import { Song } from "../models/song.model.js";
import { Album } from "../models/album.model.js";

import { PutObjectCommand } from "@aws-sdk/client-s3";
import s3Client  from "../lib/s3.js";
import fs from "fs";
import crypto  from "crypto";
import path  from "path";


export const uploadToS3 = async (file, uploadKey) => {
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

export const createSong = async (req, res, next) => {
	try {
		if (!req.files || !req.files.audioFile || !req.files.imageFile) {
			return res.status(400).json({ message: "Please upload all files" });
		}

		const { title, artist, albumId, duration } = req.body;
		const audioFile = req.files.audioFile;
		const imageFile = req.files.imageFile;

		const audioUrl = await uploadToS3(audioFile, "audio");
		const imageUrl = await uploadToS3(imageFile, "image");

		const song = new Song({
			title,
			artist,
			audioUrl,
			imageUrl,
			duration,
			albumId: albumId || null,
		});

		await song.save();

		// if song belongs to an album, update the album's songs array
		if (albumId) {
			await Album.findByIdAndUpdate(albumId, {
				$push: { songs: song._id },
			});
		}
		res.status(201).json(song);
	} catch (error) {
		console.log("Error in createSong", error);
		next(error);
	}
};

export const deleteSong = async (req, res, next) => {
	try {
		const { id } = req.params;

		const song = await Song.findById(id);

		// if song belongs to an album, update the album's songs array
		if (song.albumId) {
			await Album.findByIdAndUpdate(song.albumId, {
				$pull: { songs: song._id },
			});
		}

		await Song.findByIdAndDelete(id);

		res.status(200).json({ message: "Song deleted successfully" });
	} catch (error) {
		console.log("Error in deleteSong", error);
		next(error);
	}
};

export const createAlbum = async (req, res, next) => {
	try {
		const { title, artist, releaseYear } = req.body;
		const { imageFile } = req.files;
		
		// const imageUrl = await uploadToCloudinary(imageFile);
		const imageUrl = ""

		const album = new Album({
			title,
			artist,
			imageUrl,
			releaseYear,
		});

		await album.save();

		res.status(201).json(album);
	} catch (error) {
		console.log("Error in createAlbum", error);
		next(error);
	}
};

export const deleteAlbum = async (req, res, next) => {
	try {
		const { id } = req.params;
		await Song.deleteMany({ albumId: id });
		await Album.findByIdAndDelete(id);
		res.status(200).json({ message: "Album deleted successfully" });
	} catch (error) {
		console.log("Error in deleteAlbum", error);
		next(error);
	}
};

export const checkAdmin = async (req, res, next) => {
	res.status(200).json({ admin: true });
};
