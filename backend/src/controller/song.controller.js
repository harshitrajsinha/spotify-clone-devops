import { Song } from "../models/song.model.js";
import { GetObjectCommand } from "@aws-sdk/client-s3";
import { getSignedUrl } from "@aws-sdk/s3-request-presigner";
import s3Client from "../lib/s3.js";

const getPresignedUrl = async (key) => {
    return await getSignedUrl(
        s3Client,
        new GetObjectCommand({
            Bucket: process.env.S3_BUCKET_NAME,
            Key: key,
        }),
        { expiresIn: 3600 }
    );
};

export const getAllSongs = async (req, res, next) => {
	try {
        const songs = await Song.find().sort({ createdAt: -1 }).lean();
        const modifiedSongs = await Promise.all(
            songs.map(async (song) => ({
                ...song,
                imageUrl: await getPresignedUrl(song.imageUrl),
                audioUrl: await getPresignedUrl(song.audioUrl),
            }))
        );
        res.json(modifiedSongs);
    } catch (error) {
        next(error);
    }
};

export const getFeaturedSongs = async (req, res, next) => {
	try {
        const songs = await Song.aggregate([
            { $sample: { size: 6 } },
            {
                $project: {
                    _id: 1,
                    title: 1,
                    artist: 1,
                    imageUrl: 1,
                    audioUrl: 1,
                },
            },
        ]);
        const modifiedSongs = await Promise.all(
            songs.map(async (song) => ({
                ...song,
                imageUrl: await getPresignedUrl(song.imageUrl),
                audioUrl: await getPresignedUrl(song.audioUrl),
            }))
        );
        res.json(modifiedSongs);
    } catch (error) {
        next(error);
    }
};

export const getMadeForYouSongs = async (req, res, next) => {
	try {
		const songs = await Song.aggregate([
			{
				$sample: { size: 4 },
			},
			{
				$project: {
					_id: 1,
					title: 1,
					artist: 1,
					imageUrl: 1,
					audioUrl: 1,
				},
			},
		]);

		const modifiedSongs = await Promise.all(
            songs.map(async (song) => ({
                ...song,
                imageUrl: await getPresignedUrl(song.imageUrl),
                audioUrl: await getPresignedUrl(song.audioUrl),
            }))
        );
        res.json(modifiedSongs);
	} catch (error) {
		next(error);
	}
};

export const getTrendingSongs = async (req, res, next) => {
	try {
		const songs = await Song.aggregate([
			{
				$sample: { size: 4 },
			},
			{
				$project: {
					_id: 1,
					title: 1,
					artist: 1,
					imageUrl: 1,
					audioUrl: 1,
				},
			},
		]);

		const modifiedSongs = await Promise.all(
+            songs.map(async (song) => ({
+                ...song,
+                imageUrl: await getPresignedUrl(song.imageUrl),
+                audioUrl: await getPresignedUrl(song.audioUrl),
+            }))
+        );
+        res.json(modifiedSongs);
	} catch (error) {
		next(error);
	}
};
