import { Album } from "../models/album.model.js";
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
        { expiresIn: 300 }
    );
};

export const getAllAlbums = async (req, res, next) => {
	try {

		const albums = await Album.find();
		const modifiedAlbums = await Promise.all(
			albums.map(async (album) => ({
				...album,
				imageUrl: await getPresignedUrl(album.imageUrl),
				// audioUrl: await getPresignedUrl(album.audioUrl),
			}))
		);
		res.status(200).json(modifiedAlbums);
	} catch (error) {
		next(error);
	}
};

export const getAlbumById = async (req, res, next) => {
	try {
		const { albumId } = req.params;

		const album = await Album.findById(albumId).populate("songs");

		if (!album) {
			return res.status(404).json({ message: "Album not found" });
		}

		res.status(200).json(album);
	} catch (error) {
		next(error);
	}
};
