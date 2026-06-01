export const logout = async (req, res, next) => {
	try {
		res.clearCookie("auth_token", {
			httpOnly: true,
			secure:
				process.env.NODE_ENV ===
				"production",
			sameSite: "lax",
		});

		res.status(200).json({
			success: true,
		});
	} catch (error) {
		next(error);
	}
};