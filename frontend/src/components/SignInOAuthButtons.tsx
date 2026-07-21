import { Button } from "./ui/button";

const SignInOAuthButtons = () => {
  const signInWithGoogle = () => {
    const domain = import.meta.env.VITE_COGNITO_DOMAIN;
    const clientId = window.__CONFIG__.VITE_COGNITO_CLIENT_ID;
    const redirectUri = encodeURIComponent(
      `${window.location.origin}/auth-callback`
    );

    const authUrl =
      `${domain}/oauth2/authorize` +
      `?identity_provider=Google` +
      `&response_type=code` +
      `&client_id=${clientId}` +
      `&redirect_uri=${redirectUri}` +
      `&scope=openid+email+profile`;

      window.location.href = authUrl;
  };

  return (
    <Button
      onClick={signInWithGoogle}
      variant="secondary"
      className="w-full text-white border-zinc-200 h-11"
    >
      <img src="/google.png" alt="Google" className="size-5" />
      Continue with Google
    </Button>
  );
};

export default SignInOAuthButtons;
