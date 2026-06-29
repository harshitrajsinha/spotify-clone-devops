This project is forked from [burakorkmez/realtime-spotify-clone](https://github.com/burakorkmez/realtime-spotify-clone) to learn and showcase my skills on containerization of application, implementation of CI/CD pipeline for automatic security scanning, testing, and building and finally deploying via docker compose. I have also performed **migration** of <u>third-party services used like Clerk, Cloudinary, MongoDB</u> to <u>AWS-native solutions - AWS Cognito, S3, and DocumentDB</u>👍

<br>

<img src="./assets/spotify-arch.png" alt="Demo App" width="800" height="400"/>
<h2 align="center">Realtime Spotify Application ✨</h2><br>

```
                              --------------
                              |  Internet  |
                              --------------   
                                    |
                                 AWS ALB
                                    |
                         Target Group (Port 80)
                                    |
                               EC2 Instance
                    -----------------------------------
                                    |
                            Traefik (Port 80)
                          ┌──────────┴──────────┐
                          │                     │
                    PathPrefix("/")     PathPrefix("/api")
                          │                     │
                       Frontend              Backend

```

## 📋 <a name="table">Table of Contents</a>

1. [Tech Stack](#tech-stack)
2. [Quick Start](#quick-start)
3. [Devopsification of the project](#devops)

## <a name="tech-stack">Tech Stack</a>
<p>1. Frontend - Typescript, React, Tailwind, Zustand, Vite</p>
<p>2. Backend - Node, Express</p>
<p>3. AWS - Cognito (Auth), S3 (Object storage), DocumentDB (Database)</p>
<p>4. Traefik as reverse proxy (if using Docker)

## <a name="quick-start">Quick Start (via Docker)</a>

**Prerequisites**: Git, Docker

**Cloning the Repository**

```bash
git clone https://github.com/harshitrajsinha/spotify-clone-devops.git
cd spotify-clone-devops
```

**Set Up Environment Variables**

#### Setup .env file in _backend_ folder

```env
PORT=8000
MONGODB_URI=<mongodb cloud>
ADMIN_EMAIL=
NODE_ENV=development

CLOUDINARY_API_KEY=
CLOUDINARY_API_SECRET=
CLOUDINARY_CLOUD_NAME=

FRONTEND_URL=http://localhost # (Traefik reverse proxy endpoint)

COGNITO_DOMAIN=
COGNITO_CLIENT_ID=
COGNITO_CLIENT_SECRET=
COGNITO_REDIRECT_URI=
COGNITO_USER_POOL_ID=
```

#### Setup .env file in _frontend_ folder

```env
VITE_BACKEND_URL=http://localhost # (Traefik reverse proxy endpoint)
VITE_MODE=development
VITE_COGNITO_DOMAIN=
VITE_COGNITO_CLIENT_ID=
```
* Update frontend/nginx.conf
```bash
# Make sure nginx.conf contains backend url as
#location /api/ {
#    proxy_pass http://localhost;    <----- Traefik entrypoint
#    ...
#}
```

**Building and Running the Project**
```
docker compose up --build
```

**Loading data into database**
```
docker exec -it <backend-container-id> sh
app/ $ npm run seed:songs
app/ $ npm run seed:albums
app/ $ exit
```
NOTE: Data is loaded into database manually because adding this script into Dockerfile or Compose poses the risk of writing data into database everytime container restarts. This is problem in production, especially with large amount of data


## AWS-native architecture
![Architecture](/assets/spotify-clone-devops-arc.png)

## Migration from Clerk to AWS Cognito
* Integrated Google OAuth in AWS Cognito (same as it was available previously through Clerk), hence there is no change on User facing interface.
* On code level - majority of the authentication workload, in case of Clerk, that was handled by frontend is now shifted onto backend where frontend verifies the user and shares a code with backend, which then generate authentication cookie and save it on client's browser.
<br/>

![Aws-Cognito-flow](/assets/cognito-flow.png)
