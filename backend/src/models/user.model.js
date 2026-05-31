import mongoose from "mongoose";

const userSchema = new mongoose.Schema(
	{
		fullName: {
			type: String,
			required: true,
		},
		imageUrl: {
			type: String,
			required: true,
		},
		clerkId: {				// clerkId is the id passed by google auth in the registered callback function
			type: String,
			required: true,
			unique: true,
		},
	},
	{ timestamps: true } //  createdAt, updatedAt
);

export const User = mongoose.model("User", userSchema);
