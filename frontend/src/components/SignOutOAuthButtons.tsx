import { axiosInstance } from "@/lib/axios";
import { Button } from "./ui/button";

const SignOutButton = () => {
  const signOut = async () => {
    try {
      await axiosInstance.post(
        "/auth/logout",
        {},
        {
          withCredentials: true,
        }
      );

      const domain =
        import.meta.env.VITE_COGNITO_DOMAIN;

      const clientId =
        import.meta.env.VITE_COGNITO_CLIENT_ID;

      const logoutUri = encodeURIComponent(
        `${window.location.origin}`
      );

      window.location.href =
        `${domain}/logout` +
        `?client_id=${clientId}` +
        `&logout_uri=${logoutUri}`;
    } catch (error) {
      console.error(
        "Logout failed",
        error
      );
    }
  };

  return (
    <Button onClick={signOut}>
      Sign Out
    </Button>
  );
};

export default SignOutButton;