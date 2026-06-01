import { Router } from "express";
import { authCallback } from "../controller/auth.controller.js";
import { logout } from "../controller/logout.controller.js";

const router = Router();

router.post("/logout", logout);
router.post("/callback", authCallback);

export default router;
