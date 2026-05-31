import { User } from "../models/user.model.js";

// this method checks if user already exists based on id received from request and matching with clerkid field in mongodb user table
// if user does not exists the create an entry in mongodb table
export const authCallback = async (req, res, next) => {
	try {
		const { id, firstName, lastName, imageUrl } = req.body; // imageUrl is the user profile picture in google authentication

		// check if user already exists
		const user = await User.findOne({ clerkId: id });

		if (!user) {
			// signup, adding new user data to mongodb
			await User.create({
				clerkId: id,
				fullName: `${firstName || ""} ${lastName || ""}`.trim(),
				imageUrl,
			});
		}

		res.status(200).json({ success: true });
	} catch (error) {
		console.log("Error in auth callback", error);
		next(error);
	}
};
