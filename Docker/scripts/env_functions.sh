export_env_vars() {
    # In Docker/Railway environment, environment variables are already set
    # Don't try to load from .env file
    if [ "$DOCKER_ENV" = "true" ]; then
        echo "Running in Docker environment - using system environment variables"
        return
    fi
    
    if [ -f .env ]; then
        while IFS='=' read -r key value; do
            if [[ -z "$key" || "$key" =~ ^\s*# || -z "$value" ]]; then
                continue
            fi

            key=$(echo "$key" | tr -d '[:space:]')
            value=$(echo "$value" | tr -d '[:space:]')
            value=$(echo "$value" | tr -d "'" | tr -d "\"")

            export "$key=$value"
        done < .env
    else
        echo ".env file not found"
        exit 1
    fi
}