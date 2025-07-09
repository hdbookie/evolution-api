#!/bin/bash

source ./Docker/scripts/env_functions.sh

if [ "$DOCKER_ENV" != "true" ]; then
    export_env_vars
fi

# Export DATABASE_CONNECTION_URI to ensure it's available
export DATABASE_CONNECTION_URI

if [[ "$DATABASE_PROVIDER" == "postgresql" || "$DATABASE_PROVIDER" == "mysql" ]]; then
    echo "Deploying migrations for $DATABASE_PROVIDER"
    echo "Database URL: $DATABASE_CONNECTION_URI"
    
    # Check if DATABASE_CONNECTION_URI is empty
    if [ -z "$DATABASE_CONNECTION_URI" ]; then
        echo "Error: DATABASE_CONNECTION_URI is empty. Please set it in Railway environment variables."
        exit 1
    fi
    
    npm run db:deploy
    if [ $? -ne 0 ]; then
        echo "Migration failed"
        exit 1
    else
        echo "Migration succeeded"
    fi
    npm run db:generate
    if [ $? -ne 0 ]; then
        echo "Prisma generate failed"
        exit 1
    else
        echo "Prisma generate succeeded"
    fi
else
    echo "Error: Database provider $DATABASE_PROVIDER invalid."
    exit 1
fi