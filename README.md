<h1 align="center">Realtime Spotify Application ✨</h1>

![Demo App](/frontend/public/screenshot-for-readme.png)

[Watch Full Tutorial on Youtube](https://youtu.be/4sbklcQ0EXc)

About This Course:
-
-   🎸 Listen to music, play next and previous songs
-   🔈 Update the volume with a slider
-   🎧 Admin dashboard to create albums and songs
-   💬 Real-time Chat App integrated into Spotify
-   👨🏼‍💼 Online/Offline status
-   👀 See what other users are listening to in real-time
-   📊 Aggregate data for the analytics page
-   🚀 And a lot more...


## <a name="quick-start">Quick Start</a>


**Prerequisites**: Git, Node.js, npm, docker

**Cloning the Repository**

```bash
git clone https://github.com/harshitrajsinha/spotify-clone-devops.git
```

**Set Up configurations for backend**

cd spotify-clone-devops/backend
npm install
cp .env.sample .env

```env
PORT=8000
MONGODB_URI=
ADMIN_EMAIL=
NODE_ENV=development

FRONTEND_URL=http://localhost:3000

COGNITO_DOMAIN=
COGNITO_CLIENT_ID=
COGNITO_REDIRECT_URI=
COGNITO_USER_POOL_ID=

AWS_ACCESS_KEY_ID=
AWS_SECRET_ACCESS_KEY=
AWS_REGION=
S3_BUCKET_NAME=
```

**Running the backend Project**

```bash
cd spotify-clone-devops/backend
npm run dev
```
Open [http://localhost:8000/api/health](http://localhost:8000/api/health) to test.

**Set Up configurations for frontend**

cd spotify-clone-devops/frontend
npm install
cp .env.sample .env

```env
VITE_BACKEND_URL=http://localhost:8000
VITE_MODE=development
VITE_COGNITO_DOMAIN=
VITE_COGNITO_CLIENT_ID=
```

Replace the placeholder values with your actual credentials.

**Running the frontend Project**

```bash
cd spotify-clone-devops/frontend
npm run dev
```

Open [http://localhost:3000](http://localhost:3000) to test.

### Running application via Docker

* Create a .env file at the root directory combining env vars of backend and frontend (so that same could be used in both or create separate)

**Building and running backend docker image**

```bash
cd spotify-clone-devops
docker build -t <image-name>:<version> -f docker/Dockerfile.backend .
docker run -p 8000:8000 --env-file ./.env <image-name>:<version>
```

**Building and running frontend docker image**

```bash
cd spotify-clone-devops
# change backend url in frontend/nginx.conf as per your configuration
docker build --secret id=spotify-frontend-env,src=.env -t <image-name>:<version> -f docker/Dockerfile.frontend . # assuming .env is located in root directory with name .env
docker run -p 80:80 <image-name>:<version> # Frontend docker container is exposed on port 80 (as we are using nginx as proxy server)
```