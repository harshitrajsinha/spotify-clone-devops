import { Card, CardContent } from "@/components/ui/card";
import { axiosInstance } from "@/lib/axios";
import { Loader } from "lucide-react";
import { useEffect, useRef } from "react";
import { useNavigate } from "react-router-dom";
import { useAuthStore } from "@/stores/useAuthStore";

const AuthCallbackPage = () => {
  const navigate = useNavigate();
  const callbackAttempted = useRef(false);
  const { checkAdminStatus } = useAuthStore();

  useEffect(() => {
    const processCallback = async () => {
      if (callbackAttempted.current) return;

      callbackAttempted.current = true;

      const code = new URLSearchParams(
        window.location.search
      ).get("code");

      if (!code) {
        console.error("No authorization code found");
        navigate("/login");
        return;
      }

      try {
        await axiosInstance.post("/auth/callback", {
          code,
        });

        await axiosInstance.get(
          "/auth/me",
          {
            withCredentials: true,
          }
        );

        await checkAdminStatus();

        navigate("/");
      } catch (error) {
        console.error(
          "Error processing auth callback",
          error
        );

        navigate("/login");
      }
    };

    processCallback();
  }, [navigate]);

  return (
    <div className="h-screen w-full bg-black flex items-center justify-center">
      <Card className="w-[90%] max-w-md bg-zinc-900 border-zinc-800">
        <CardContent className="flex flex-col items-center gap-4 pt-6">
          <Loader className="size-6 text-emerald-500 animate-spin" />
          <h3 className="text-zinc-400 text-xl font-bold">
            Logging you in
          </h3>
          <p className="text-zinc-400 text-sm">
            Redirecting...
          </p>
        </CardContent>
      </Card>
    </div>
  );
};

export default AuthCallbackPage;


