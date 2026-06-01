import "dotenv/config";
import { CognitoJwtVerifier } from "aws-jwt-verify";
const verifier =
	CognitoJwtVerifier.create({
		userPoolId: process.env.COGNITO_USER_POOL_ID,
		tokenUse: "id",
		clientId: process.env.COGNITO_CLIENT_ID,
	});

export const protectRoute = async (req, res, next) => {
	try {
		const token =
			req.cookies.auth_token;

		if (!token) {
			return res.status(401).json({
				message:
					"Unauthorized - Login required",
			});
		}

		const payload =
			await verifier.verify(token);

		req.user = payload;

		next();
	} catch (error) {
		console.log(
			"JWT verification failed:",
			error
		);

		return res.status(401).json({
			message:
				"Unauthorized - Invalid token",
		});
	}
};

export const requireAdmin = async (req, res, next) => {
	try {
		if (
			req.user.email !==
			process.env.ADMIN_EMAIL
		) {
			return res.status(403).json({
				message:
					"Unauthorized - Admin only",
			});
		}

		next();
	} catch (error) {
		next(error);
	}
};