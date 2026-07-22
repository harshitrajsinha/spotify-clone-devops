This project is forked from [burakorkmez/realtime-spotify-clone](https://github.com/burakorkmez/realtime-spotify-clone) to learn and showcase my skills on containerization of application, implementation of CI/CD pipeline for automatic security scanning, testing, and building and finally deploying via docker compose. I have also performed **migration** of <u>third-party services used like Clerk, Cloudinary, MongoDB</u> to <u>AWS-native solutions - AWS Cognito, S3, and DocumentDB</u>👍

<br>

<img src="./assets/project-system-architecture.png" alt="Demo App" width="800" height="400"/>

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
3. [Devopsification of the project - Dockerization, Continuous Ingegration, Terraform, AWS Architecture, Deployment](#devops)
4. [Future enhancements and implementations](#future-implementations)

## <a name="tech-stack">Tech Stack</a>
<p>1. Frontend - Typescript, React, Tailwind, Zustand, Vite</p>
<p>2. Backend - Node, Express</p>
<p>3. AWS - Cognito (Auth), S3 (Object storage), DocumentDB (Database)</p>
<p>4. Traefik as reverse proxy (if using Docker)

## <a name="quick-start">Quick Start (via Docker Compose)</a>

**Prerequisites**: Git, Docker

**Cloning the Repository**

```bash
git clone https://github.com/harshitrajsinha/groovify-devops.git
cd groovify-devops
```

**Set Up Environment Variables**

#### Setup .env file in _backend_ folder

```env
PORT=8000
MONGODB_URI=<mongodb cloud>
ADMIN_EMAIL=
NODE_ENV=development

AWS_REGION=
S3_BUCKET_NAME=

# AWS_ACCESS_KEY_ID
# AWS_SECRET_ACCESS_KEY

FRONTEND_URL=http://localhost # (Traefik reverse proxy endpoint)

COGNITO_DOMAIN=
COGNITO_CLIENT_ID=
COGNITO_CLIENT_SECRET=
COGNITO_REDIRECT_URI=
COGNITO_USER_POOL_ID=
```

#### Setup config.js file in _frontend_ folder 
* config.js is used over env to provide env vars at build time. The vars are not secret hence can be exposed through config file.

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

NOTE: Data is loaded into database manually because adding this script into Dockerfile or Compose poses the risk of writing data into database everytime container restarts. This is problem in production, especially with large amount of data

# <a name="devops">Devopsifying the project</a>

### 🐳 Dockerizing frontend and backend application

The backend and frontend services have been successfully containerized using a multi-stage Docker build approach, with `node:24.16.0-alpine3.23` and `nginx:stable-alpine3.23` as the respective final-stage base images. As a result, the final application images are only 16% (backend) and 4% (frontend) larger than their minimal runtime base images, by following Docker image optimization best practices

![docker-image](./assets/project-docker-image.png) 

#### Learnings:

* Improved the build time by combining copying and changing file ownership into single command (this could have significant impact depending on number of application files)
<br/><br/>
<hr>

### 🔄 Continuous Integration

A successful CI pipeline is built that runs when code changes are pushed for frontend and backend on dev (development) and main (production) branch. Depending on the environment development/production, different tasks are performed under the following jobs - 1. Security Scan, 2. Linting, 3. Test, 4. Image build and scan, 5. Release to DockerHub, 6. Commit new image tag to docker-compose file

![ci-pipeline-image](./assets/ci-pipeline.png) 


#### Learnings:
1. How different tools are used to scan and secure the project, and choosing the right tool for development or production based on its impact on pipeline duration and performance.
2. How to include a human approval step using the environment argument to ensure that the code being deployed to production is the expected version.

<hr>

### 🏗️ Terraform (Infrastructure as Code)

The application infrastructure consists of total of 84 terraform resources that are created from 12 different AWS services that facilitates the flow of request between client, DevOps engineer and application server, along with other AWS resources that integrates with the application like database, object storage etc. A list of which could be found in the following link - 
[https://raw.githubusercontent.com/harshitrajsinha/groovify-devops/refs/heads/main/terraform/app-infra-resources.json](https://raw.githubusercontent.com/harshitrajsinha/groovify-devops/refs/heads/main/terraform/app-infra-resources.json)

Terraform CI pipeline: CI pipeline for terraform ensures that any new commit on terraform resources code must go through security check, syntax check, vulnerability scan before being merged.

Code commit? → Secrets scan → Format check (terraform fmt) → Validation check (terraform validate) → Linting (using TFLint) → Vulnerability scan (using Trivy)

<hr>

## AWS architecture
![Architecture](/assets/groovify-aws-arc.png)

The two main services in the project - Frontend and Backend, both run on t3a.medium EC2 instance, along with Traefik (used as reverse proxy to load balance containers + path-based routing). The instance is provisioned in private subnet, which can be accessed by "clients" requests through ALB Load Balancer, and "engineers" through AWS System Manager (SSM) Agent. VPC endpoints are used for internal communication of instance with other AWS services.

### Migration from Clerk to AWS Cognito
The migration from Clerk to AWS Cognito was the most challenging part because it required significant changes to the authentication flow. With Clerk, most of the authentication logic is abstracted away. With AWS Cognito - after Google authenticates the user, it redirects back to Cognito, which validates the user and issues its own authorization code. The frontend forwards this code to the backend, which exchanges it with Cognito for the authentication tokens and user information before establishing the user's session. In case of Cognito, the user token is generated by backend (at least in the approach that I adopted).
<br/>

### Migration from Cloudinary to S3
In case of cloudinary, the upload function uses a one-liner cloudinary SDK that retrieves the targeted file from temporary storage and returns a secure URL to get that file/object directly via the URL. S3 involves generating a UUID as key that uniquely defines any object. Originally, the project preloaded songs and albums from the public directory of the frontend service. Although this approach was simple, it significantly increased the size of the frontend image. To address this, the preloaded assets were moved to a separate service that runs once during deployment and populates Amazon S3 and the database with the initial songs and albums, ensuring that the application has seed data available from the start.
<br/>

### Migrating from MongoDB to AWS DocumentDB
This was the easiest among the three migrations as it involved only changing the connection string in the environment variable and adding AWS CA certification for establishing SSL/TLS connection to the DocumentDB cluster. The rest of the code for CRUD operations remain same.
<br/>

## Deployment

* Currently, the deployment process is manual. On infrastructure build, the application stack is deployed onto the server via an EC2 user-data script that pulls source code from the GitHub repository, prepares environment variable files and finally spins up the frontend and backend containers via Docker Compose.
* On any further code changes, a rolling update script is prepared for deploying new image containers and discarding old ones. It pulls the latest image from Docker Hub and then, based on container labels, identifies the running container. For each running container, it spins up a new container from the new image, waits for it to be in a healthy state, and then spins down the old container. This ensures zero to near-zero downtime.

# <a name="future-implementations">Future enhancements and implementations</a>

1. Implement CloudFront (CDN) to cache frequently accessed static assets.
2. Perform security scanning on uploaded songs to prevent malicious files from being stored in Amazon S3.
3. Implement an automated deployment pipeline following security best practices and project requirements.
4. Introduce observability to monitor server health, application performance, and response times.

<hr>

* Full write is available on Medium: (https://medium.com/@_rajSinha08/groovify-devops-project-47d9d840873b)[https://medium.com/@_rajSinha08/groovify-devops-project-47d9d840873b]