set -euo pipefail

exec > >(sudo tee -a /tmp/user-data.log) 2>&1

##############################################################
# Create .env file in backend and frontend by fetching values from AWS SSM parameter store
AWS_REGION="us-east-1"
PROJECT_DIR="/home/ubuntu/groovify-devops" # IN user-data, $USER corresponds to root, hence hard-coding user name


BACKEND_ENV_FILE="${PROJECT_DIR}/backend/.env"
> "$BACKEND_ENV_FILE" # Truncate or create file


for name in PORT MONGODB_URI ADMIN_EMAIL NODE_ENV S3_BUCKET_NAME AWS_REGION FRONTEND_URL COGNITO_DOMAIN COGNITO_CLIENT_ID COGNITO_CLIENT_SECRET COGNITO_REDIRECT_URI COGNITO_USER_POOL_ID; do
    value=$(aws ssm get-parameter --name "/groovify/$name" --with-decryption --query "Parameter.Value" --output text --region "$AWS_REGION")
    echo "${name}=${value}" >> "$BACKEND_ENV_FILE"
done

chown ubuntu:ubuntu "$BACKEND_ENV_FILE"
chmod 600 "$BACKEND_ENV_FILE"

FRONTEND_ENV_FILE="${PROJECT_DIR}/frontend/.env"
> "$FRONTEND_ENV_FILE"

for name in VITE_BACKEND_URL VITE_COGNITO_DOMAIN VITE_COGNITO_CLIENT_ID; do
    value=$(aws ssm get-parameter --name "/groovify/$name" --with-decryption --query "Parameter.Value" --output text --region "$AWS_REGION")
    echo "${name}=${value}" >> "$FRONTEND_ENV_FILE"
done

chown ubuntu:ubuntu "$FRONTEND_ENV_FILE"
chmod 600 "$FRONTEND_ENV_FILE"

# Updating VITE_COGNITO_CLIENT_ID in config.js to serve at runtime

CONFIG_FILE="${PROJECT_DIR}/frontend/config.js"

for name in VITE_COGNITO_CLIENT_ID; do
    value=$(aws ssm get-parameter \
        --name "/groovify/$name" \
        --with-decryption \
        --query "Parameter.Value" \
        --output text \
        --region "$AWS_REGION")

    # Escape characters that sed treats specially
    escaped_value=$(printf '%s' "$value" | sed 's/[\/&]/\\&/g')

    sed -i "s|__${name}__|${escaped_value}|g" "$CONFIG_FILE"
done
##############################################################

# Run reverse proxy, backend and frontend service in background through docker compose
cd "${PROJECT_DIR}"
sudo docker compose up -d --build


##############################################################