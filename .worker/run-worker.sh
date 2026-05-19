#!/bin/bash

# Check if .env exists in .worker or root
if [ -f ".worker/.env" ]; then
    ENV_FILE=".worker/.env"
elif [ -f ".env" ]; then
    ENV_FILE=".env"
fi

if [ -n "$ENV_FILE" ]; then
    if grep -q 'REPO="USER/REPO"' "$ENV_FILE" || grep -q "REPO='USER/REPO'" "$ENV_FILE" || grep -q "REPO=USER/REPO" "$ENV_FILE"; then
        echo "⚠️  AVISO: A variável REPO no arquivo $ENV_FILE ainda está configurada como 'USER/REPO'."
        echo "Por favor, edite o arquivo e coloque o endereço correto do seu repositório (ex: org/repo)."
        echo ""
        read -p "Deseja continuar assim mesmo? (y/N) " confirm
        if [[ ! $confirm =~ ^[Yy]$ ]]; then
            echo "Operação cancelada."
            exit 1
        fi
    fi
fi

export GH_TOKEN=$(gh auth token)
docker compose -f .worker/docker-compose.worker.yml up --build
