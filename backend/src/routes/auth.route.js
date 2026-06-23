import { Router } from "express";
import { authCallback } from "../controller/auth.controller.js";
import { protectRoute, getCurrentUser } from "../middleware/auth.middleware.js";
import { logout } from "../controller/logout.controller.js";

const router = Router();

router.get("/", async (req, res, next) => {
    res.status(200).json({
        success: true,
        message: "Health check endpoint",
    });
});

router.get("/me", protectRoute, getCurrentUser);
router.post("/logout", logout);
router.post("/callback", authCallback);

export default router;
