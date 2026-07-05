import path from "path";
import fs from "fs";
import { fileURLToPath } from "url";
import mongoose from "mongoose";


import { Song } from "./song.model.js";
import uploadToS3 from "./s3.js";

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
    });
    
    await song.save();

    return song;

  } catch (error) {
    console.log("Error in saving song", error);
    throw new Error("Error saving song");
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