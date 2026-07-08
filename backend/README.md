# Building backend applications via npm

1. Setup .env in backend/ directory (refer .env.sample)
```env
PORT=8000
MONGODB_URI=mongodb+srv://username:password@cluster0.sampleurl.mongodb.net/spotify?appName=Cluster0
ADMIN_EMAIL=youremailid@emailprovider
NODE_ENV=development

AWS_REGION=
S3_BUCKET_NAME=

# AWS_ACCESS_KEY_ID
# AWS_SECRET_ACCESS_KEY

FRONTEND_URL=http://localhost:3000

COGNITO_DOMAIN=https://us-east-sampleurl.auth.us-east-1.amazoncognito.com
COGNITO_CLIENT_ID=3aa3aaa2aa220a12a2346aa5aa
COGNITO_CLIENT_SECRET=clientsecret
COGNITO_REDIRECT_URI=http://localhost:3000/auth-callback
COGNITO_USER_POOL_ID=us-east-sampleid
```

2. Install dependencies
```bash
npm install
```

3. Run in development mode
```bash
npm run dev
```
