import path from "path";
import fs from "fs";
import { fileURLToPath } from "url";
import mongoose from "mongoose";

import { Album } from "./album.model.js";
import { Song } from "./song.model.js";
import uploadToS3 from "./s3.js";

import dotenv from "dotenv";
dotenv.config();

const __dirname = path.dirname(fileURLToPath(import.meta.url));

const ALBUMS_DIR = path.join(__dirname, "albums");
const METADATA_PATH = path.join(__dirname, "albums-metadata.json");

const MIME_TYPES = {
  ".jpg": "image/jpeg",
  ".jpeg": "image/jpeg",
  ".png": "image/png",
  ".webp": "image/webp",
};

const getMimeType = (ext) => MIME_TYPES[ext.toLowerCase()] || "application/octet-stream";

const saveAlbum = async ({ title, artist, imageFilePath, releaseYear, songsList }) => {
    try{ 

        const imageExt = path.extname(imageFilePath);

        const imageFile = {
            name: path.basename(imageFilePath),
            tempFilePath: imageFilePath,
            mimetype: getMimeType(imageExt),
        };

        const imageUrl = await uploadToS3(imageFile, "image");

        // Save to database
        const album = new Album({
            title,
            artist,
            imageUrl,
            releaseYear,
            songs: songsList,
        });
        
        await album.save();

        return album;
    } catch (error) {
		console.log("Error in saving album", error);
        throw new Error("Error saving album");
	}
};


const seedAlbums = async () => {

    try {

        // create database connection
        await mongoose.connect(process.env.MONGODB_URI);

        const metadata = JSON.parse(fs.readFileSync(METADATA_PATH, "utf-8"));

        // loop through each object in songs-metadata.json
        for (const entry of metadata) {

            const { title, artist, releaseYear, imageFileName, songs } = entry;
            const imageFilePath = path.join(ALBUMS_DIR, imageFileName);


            if (!fs.existsSync(imageFilePath)) {
                console.warn(`Skipping "${title}" — missing file(s)`);
                continue;
            }

            console.log(`Uploading: ${title}`);
        
            // check if album already exists in database
            const existing = await Album.findOne({ title, artist });
            if (existing) {
                console.log(`Skipping "${title}" — already exists in DB`);
                continue;
            }

            // get song id list from songs metadata
            const songsList = (
                await Promise.all(
                    songs.map(async (song) => {
                    const existingSong = await Song.findOne({
                        title: song.title,
                        artist: song.artist,
                    });

                    return existingSong ? existingSong._id : null;
                    })
                )
            ).filter((id) => id !== null);

            // upload to s3 and save to db
            const album = await saveAlbum({
                title,
                artist,
                imageFilePath,
                releaseYear,
                songsList
            });

            console.log(`✅ Saved: ${album.title}`);
        }

        console.log("Seeding complete.");
        process.exit(0);
        
    } catch (error) {
        console.error("Error seeding albums:", error);
        process.exit(1);
    }
};

seedAlbums();