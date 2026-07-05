# Building applications via Docker

We will <u>use root directory as the current context</u> to build images and reference all files from the root directory, as done in Dockerfile as well to copy application files from frontend/ and backend/ directories.
<br/><br/>
Also, <u>frontend port is changed from 3000 to 80</u> as nginx is used to serve frontend files

### Building and running backend container

1. Setup .env in backend/ directory (refer .env.sample)
```env
PORT=8000
MONGODB_URI=<using mongodb cloud>
ADMIN_EMAIL=
NODE_ENV=development

CLOUDINARY_API_KEY=
CLOUDINARY_API_SECRET=
CLOUDINARY_CLOUD_NAME=

FRONTEND_URL=http://localhost:80

COGNITO_DOMAIN=
COGNITO_CLIENT_ID=
COGNITO_CLIENT_SECRET=
COGNITO_REDIRECT_URI=
COGNITO_USER_POOL_ID=
```

2. Run docker build command from root directory of project

```
docker build -t harshitrajsinha/backend:v1 -f docker/Dockerfile.backend .
```

3. Run docker run command from root directory of project
```bash
docker run -p 8000:8000 --env-file ./backend/.env harshitrajsinha/backend:v1
```

### Building and running frontend container

1. Setup .env in frontend/ directory (refer .env.sample)
```env
VITE_BACKEND_URL=http://localhost:8000
VITE_MODE=development
VITE_COGNITO_DOMAIN=
VITE_COGNITO_CLIENT_ID=
```

2. Update frontend/nginx.conf
```bash
# Make sure nginx.conf contains backend url as
#location /api/ {
#    proxy_pass http://localhost:8000;    <-----
#    ...
#}
```

3. Run docker build command from root directory of project

```bash
docker build --secret id=spotify-frontend-env,src=frontend/.env -t harshitrajsinha/frontend:v1 -f docker/Dockerfile.frontend .
```

4. Run docker run command from root directory of project
```bash
 docker run -p 80:80 -d harshitrajsinha/frontend:v1
```
