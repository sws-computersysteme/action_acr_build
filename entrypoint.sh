#!/usr/bin/env bash
set -euo pipefail

# Default values
INPUT_DOCKERFILE="${INPUT_DOCKERFILE:-Dockerfile}"
INPUT_TAG="${INPUT_TAG:-${GITHUB_SHA::8}}"
INPUT_BRANCH="${INPUT_BRANCH:-master}"
IMAGE_PART=""
BUILD_ARGS=""

# Prepare build arguments if provided
if [[ -n "${INPUT_BUILD_ARGS:-}" ]]; then
    BUILD_ARGS=$(echo -n "${INPUT_BUILD_ARGS}" | jq -j '.[] | keys[] as $k | values[] as $v | "--build-arg \($k)=\"\($v)\" "')
fi

# Set image part if image name is given
if [[ -n "${INPUT_IMAGE:-}" ]]; then
    IMAGE_PART="/${INPUT_IMAGE}"
fi

# Add Git access token if available
GIT_ACCESS_TOKEN_FLAG=""
if [[ -n "${INPUT_GIT_ACCESS_TOKEN:-}" ]]; then
    GIT_ACCESS_TOKEN_FLAG="${INPUT_GIT_ACCESS_TOKEN}@"
fi

# Summary
echo "-----------------------------------------------------"
echo "Building Docker image:"
echo "  Registry:        ${INPUT_REGISTRY}"
echo "  Repository:      ${INPUT_REPOSITORY}${IMAGE_PART}"
echo "  Tag:             ${INPUT_TAG}"
echo "  Source:          ${GITHUB_REPOSITORY} (Branch: ${INPUT_BRANCH})"
echo "  Context Folder:  ${INPUT_FOLDER}"
echo "-----------------------------------------------------"

# Azure login
echo "Logging into Azure Container Registry..."
az login --service-principal \
    --username "${INPUT_SERVICE_PRINCIPAL}" \
    --password "${INPUT_SERVICE_PRINCIPAL_PASSWORD}" \
    --tenant "${INPUT_TENANT}"

# Build and push image
echo "Starting build job on ACR..."
az acr build \
    -r "${INPUT_REGISTRY}" \
    ${BUILD_ARGS} \
    -f "${INPUT_DOCKERFILE}" \
    -t "${INPUT_REPOSITORY}${IMAGE_PART}:${INPUT_TAG}" \
    "https://${GIT_ACCESS_TOKEN_FLAG}github.com/${GITHUB_REPOSITORY}.git#${INPUT_BRANCH}:${INPUT_FOLDER}"
