This project is forked from [burakorkmez/realtime-spotify-clone](https://github.com/burakorkmez/realtime-spotify-clone) to learn and showcase **migration** of this application from <u>third-party services like Clerk, Cloudinary, MongoDB</u> to <u>AWS-native solutions like - AWS Cognito, S3, and DocumentDB</u>, along with containerizing the application and implementing CI/CD pipeline to continuously scan, build and deploy 👍

<br>

![Demo App](/frontend/public/screenshot-for-readme.png)
<h2 align="center">Realtime Spotify Application ✨</h2><br>

### Setup .env file in _backend_ folder

```bash
PORT=
MONGODB_URI=
ADMIN_EMAIL=
NODE_ENV=

CLOUDINARY_API_KEY=
CLOUDINARY_API_SECRET=
CLOUDINARY_CLOUD_NAME=

FRONTEND_URL=

COGNITO_DOMAIN=
COGNITO_CLIENT_ID=
COGNITO_CLIENT_SECRET=
COGNITO_REDIRECT_URI=
COGNITO_USER_POOL_ID=
```

### Setup .env file in _frontend_ folder

```bash
VITE_BACKEND_URL=

VITE_COGNITO_DOMAIN=
VITE_COGNITO_CLIENT_ID=
```

## AWS-native architecture
![Architecture](/assets/spotify-clone-devops-arc.png)

## Migration from Clerk to AWS Cognito
* Integrated Google OAuth in AWS Cognito (same as it was available previously through Clerk), hence there is no change on User facing interface.
* On code level - majority of the authentication workload, in case of Clerk, that was handled by frontend is now shifted onto backend where frontend verifies the user and shares a code with backend, which then generate authentication cookie and save it on client's browser.
