// seedSongs.js
import fs from "fs";
import path from "path";
import { fileURLToPath } from "url";
import mongoose from "mongoose";
import { Song } from "./song.model.js";
import { PutObjectCommand } from "@aws-sdk/client-s3";
import s3Client from "./s3.js";
import crypto  from "crypto";

import dotenv from "dotenv";
dotenv.config();

const __dirname = path.dirname(fileURLToPath(import.meta.url));

const SONGS_DIR = path.join(__dirname, "songs");
const COVER_DIR = path.join(__dirname, "cover-images");
const METADATA_PATH = path.join(__dirname, "songs-metadata.json");

const MIME_TYPES = {
  ".mp3": "audio/mpeg",
  ".wav": "audio/wav",
  ".m4a": "audio/mp4",
  ".jpg": "image/jpeg",
  ".jpeg": "image/jpeg",
  ".png": "image/png",
  ".webp": "image/webp",
};

const getMimeType = (ext) => MIME_TYPES[ext.toLowerCase()] || "application/octet-stream";

const uploadToS3 = async (file, uploadKey) => {
  try {

    let key = ""
    const ext = path.extname(file.name);
    if (uploadKey === "audio"){
      key = `songs/${crypto.randomUUID()}${ext}`;
    }else if (uploadKey === "image") {
      key = `thumbnail/${crypto.randomUUID()}${ext}`;
    }

    const result = await s3Client.send(
      new PutObjectCommand({
        Bucket: process.env.S3_BUCKET_NAME,
        Key: key,
        Body: fs.createReadStream(file.tempFilePath),
        ContentType: file.mimetype
      })
    );

    return key;

  } catch (error) {
    console.log("Error while uploading to S3", error);
    throw new Error("Error uploading to S3");
  }
};

const saveSong = async ({ title, artist, duration, audioFilePath, imageFilePath }) => {
  try{ 

    const audioExt = path.extname(audioFilePath);
    const imageExt = path.extname(imageFilePath);
    
    const audioFile = {
      name: path.basename(audioFilePath),
      tempFilePath: audioFilePath,
      mimetype: getMimeType(audioExt),
    };
  
    const imageFile = {
      name: path.basename(imageFilePath),
      tempFilePath: imageFilePath,
      mimetype: getMimeType(imageExt),
    };

    const audioUrl = await uploadToS3(audioFile, "audio");
    const imageUrl = await uploadToS3(imageFile, "image");

    // Save to database
    const song = new Song({
      title,
      artist,
      audioUrl,
      imageUrl,
      duration,
      // albumId: albumId || null,
    });
    
    await song.save();

    // if song belongs to an album, update the album's songs array
    // if (albumId) {
    //   await Album.findByIdAndUpdate(albumId, {
    //     $push: { songs: song._id },
    //   });
    // }
    return song;
  } catch (error) {
		console.log("Error in saving song", error);
    throw new Error("Error saving songs");
	}
};


const seedSongs = async () => {

  try {

    // create database connection
    await mongoose.connect(process.env.MONGODB_URI);

    const metadata = JSON.parse(fs.readFileSync(METADATA_PATH, "utf-8"));

    // loop through each object in songs-metadata.json
    for (const entry of metadata) {

      const { title, artist, duration, audioFileName, imageFileName } = entry;

      const audioFilePath = path.join(SONGS_DIR, audioFileName);
      const imageFilePath = path.join(COVER_DIR, imageFileName);

      if (!fs.existsSync(audioFilePath) || !fs.existsSync(imageFilePath)) {
        console.warn(`Skipping "${title}" — missing file(s)`);
        continue;
      }

      console.log(`Uploading: ${title}`);
      
      // check if songs already exists in database
      const existing = await Song.findOne({ title, artist });
      if (existing) {
        console.log(`Skipping "${title}" — already exists in DB`);
        continue;
      }

      // upload to s3 and save to db
      const song = await saveSong({
        title,
        artist,
        duration,
        audioFilePath,
        imageFilePath,
      });

      console.log(`✅ Saved: ${song.title}`);
    }

    console.log("Seeding complete.");
    process.exit(0);
  } catch (error) {
    console.error("Error seeding songs:", error);
    process.exit(1);
  }
};

seedSongs();