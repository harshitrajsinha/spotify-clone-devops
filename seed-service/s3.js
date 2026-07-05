import path from "path";
import fs from "fs";
import { PutObjectCommand } from "@aws-sdk/client-s3";
import crypto  from "crypto";

import dotenv from "dotenv";
dotenv.config();

import { S3Client } from "@aws-sdk/client-s3";

const s3Client = new S3Client({
  region: process.env.AWS_REGION,
});

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

export default uploadToS3;