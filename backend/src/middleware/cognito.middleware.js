import { CognitoJwtVerifier } from "aws-jwt-verify";

const verifier = CognitoJwtVerifier.create({
	userPoolId: process.env.COGNITO_USER_POOL_ID,
	clientId: process.env.COGNITO_CLIENT_ID,
	tokenUse: "access",
});

export const cognitoMiddleware = async (req, res, next) => {
	try {
		const authHeader = req.headers.authorization;

		if (!authHeader?.startsWith("Bearer ")) {
			req.user = null;
			return next();
		}

		const token = authHeader.split(" ")[1];

		const payload = await verifier.verify(token);

		req.user = payload;

		next();
	} catch (error) {
		req.user = null;
		next();
	}
};

export const protectRoute = (req, res, next) => {
	// if (!req.user) {
	// 	return res.status(401).json({
	// 		message: "Unauthorized - you must be logged in",
	// 	});
	// }

	// next();

    if (!req.session.userInfo) {
        req.isAuthenticated = false;
    } else {
        req.isAuthenticated = true;
    }
    next();
};