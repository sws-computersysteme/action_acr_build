#!/bin/bash

set -euo pipefail

echo "🚀 Starte Azure Docker Build and Push Action..."

# Eingaben lesen
SERVICE_PRINCIPAL="$1"
SERVICE_PRINCIPAL_PASSWORD="$2"
TENANT="$3"
REGISTRY="$4"
REPOSITORY="$5"
GIT_ACCESS_TOKEN="$6"
IMAGE="${7:-app}"
TAG="${8:-}"
BRANCH="${9:-master}"
FOLDER="${10}"
DOCKERFILE="${11:-Dockerfile}"
BUILD_ARGS_JSON="${12:-}"

# Validation der Pflichtfelder
if [[ -z "$SERVICE_PRINCIPAL" || -z "$SERVICE_PRINCIPAL_PASSWORD" || -z "$TENANT" || -z "$REGISTRY" || -z "$REPOSITORY" || -z "$GIT_ACCESS_TOKEN" || -z "$FOLDER" ]]; then
  echo "❌ Fehler: Pflichtfelder fehlen."
  exit 1
fi

# Default TAG setzen, wenn nicht übergeben
if [[ -z "$TAG" ]]; then
  TAG=$(echo "${GITHUB_SHA:-$(date +%s)}" | cut -c1-8)
  echo "ℹ️ Kein Tag angegeben. Verwende automatisch: $TAG"
fi

echo "🔐 Azure Login..."
az login --service-principal -u "$SERVICE_PRINCIPAL" -p "$SERVICE_PRINCIPAL_PASSWORD" --tenant "$TENANT" --output none

echo "🔓 Login in Azure Container Registry..."
az acr login --name "$REGISTRY"

# Repo clonen
TEMP_DIR=$(mktemp -d)
cd "$TEMP_DIR"

echo "📥 Klone Repository $REPOSITORY..."
git clone "https://$GIT_ACCESS_TOKEN@github.com/$REPOSITORY.git" repo
cd repo

echo "📂 Checkout Branch $BRANCH..."
git checkout "$BRANCH"

# In das Source-Folder wechseln
cd "$FOLDER"

# Build-Command vorbereiten
echo "⚙️ Docker Build wird vorbereitet..."
BUILD_CMD="docker build -f $DOCKERFILE -t $REGISTRY.azurecr.io/$IMAGE:$TAG ."

# Build-Args anhängen, falls vorhanden
if [[ -n "$BUILD_ARGS_JSON" ]]; then
  echo "➕ Anwenden von Build-Args..."
  for row in $(echo "${BUILD_ARGS_JSON}" | jq -r 'to_entries | .[] | "\(.key)=\(.value)"'); do
    BUILD_CMD+=" --build-arg $row"
  done
fi

echo "🏗️ Führe Build aus:"
echo "$BUILD_CMD"
eval "$BUILD_CMD"

echo "🚚 Push Docker Image nach ACR..."
docker push "$REGISTRY.azurecr.io/$IMAGE:$TAG"

echo "✅ Erfolg: Image $REGISTRY.azurecr.io/$IMAGE:$TAG wurde erfolgreich gebaut und gepusht."

# Aufräumen
echo "🧹 Aufräumen..."
rm -rf "$TEMP_DIR"

echo "🏁 Fertig!"
