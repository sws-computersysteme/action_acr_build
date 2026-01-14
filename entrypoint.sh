#!/usr/bin/env bash
set -euo pipefail

# Default values
INPUT_DOCKERFILE="${INPUT_DOCKERFILE:-Dockerfile}"
INPUT_TAG="${INPUT_TAG:-${GITHUB_REF_NAME}}"
INPUT_BRANCH="${INPUT_BRANCH:-${GITHUB_REF_NAME}}"

# Automatisch Repository bestimmen, wenn nicht übergeben
if [[ -z "${INPUT_REPOSITORY:-}" ]]; then
  INPUT_REPOSITORY="${GITHUB_REPOSITORY#*/}"
fi

IMAGE_PART=""
BUILD_ARGS=""

# Set image part if image name is given
if [[ -n "${INPUT_IMAGE:-}" ]]; then
    IMAGE_PART="/${INPUT_IMAGE}"
fi

# Add Git access token if available
GIT_ACCESS_TOKEN_FLAG=""
if [[ -n "${INPUT_GIT_ACCESS_TOKEN:-}" ]]; then
    GIT_ACCESS_TOKEN_FLAG="${INPUT_GIT_ACCESS_TOKEN}@"
fi

# --- NEU: Set Environment Variables ---
CI_REPOSITORY_NAME="${INPUT_REPOSITORY}"
CI_ACTION_REF_NAME="${GITHUB_REF_NAME}"
NODE_VERSION=""

# Read .node-version file if exists (considering the INPUT_FOLDER)
NODE_VERSION_FILE="${GITHUB_WORKSPACE}/${INPUT_FOLDER}/.node-version"
if [[ -f "${NODE_VERSION_FILE}" ]]; then
    NODE_VERSION=$(cat "${NODE_VERSION_FILE}" | tr -d '[:space:]')
else
    echo ".node-version file not found at ${NODE_VERSION_FILE}, skipping NODE_VERSION setting."
fi

# Erst INPUT_BUILD_ARGS verarbeiten (falls vorhanden)
BUILD_ARGS_FROM_INPUT=""
if [[ -n "${INPUT_BUILD_ARGS:-}" ]]; then
  if echo "${INPUT_BUILD_ARGS}" | jq empty >/dev/null 2>&1; then
    BUILD_ARGS_FROM_INPUT=$(echo -n "${INPUT_BUILD_ARGS}" | jq -j '.[] | keys[] as $k | values[] as $v | "--build-arg \($k)=\"\($v)\" "' || true)
  else
    echo "Warning: INPUT_BUILD_ARGS is not valid JSON, skipping build args."
  fi
fi

# Jetzt dynamisch NODE_VERSION ergänzen, falls vorhanden
if [[ -n "${NODE_VERSION}" ]]; then
    BUILD_ARGS="--build-arg NODE_VERSION=${NODE_VERSION} ${BUILD_ARGS_FROM_INPUT}"
else
    BUILD_ARGS="${BUILD_ARGS_FROM_INPUT}"
fi

echo "-----------------------------------------------------"
echo "Environment Variables:"
echo "  CI_REPOSITORY_NAME=${CI_REPOSITORY_NAME}"
echo "  CI_ACTION_REF_NAME=${CI_ACTION_REF_NAME}"
echo "  NODE_VERSION=${NODE_VERSION}"
echo "-----------------------------------------------------"

# Azure login
echo "Logging into Azure Container Registry..."
az login --service-principal \
    --username "${INPUT_SERVICE_PRINCIPAL}" \
    --password "${INPUT_SERVICE_PRINCIPAL_PASSWORD}" \
    --tenant "${INPUT_TENANT}"

# Decide between local context or Git URL
if [[ -n "${INPUT_GIT_ACCESS_TOKEN:-}" ]]; then
    # Use Git URL if token is provided
    BUILD_CONTEXT="https://${GIT_ACCESS_TOKEN_FLAG}github.com/${GITHUB_REPOSITORY}.git#${INPUT_BRANCH}:${INPUT_FOLDER}"
    echo "Build context: Git URL"
    echo "  ${BUILD_CONTEXT}"
else
    # Use local checkout
    BUILD_CONTEXT="${GITHUB_WORKSPACE}/${INPUT_FOLDER}"
    echo "Build context: Local directory"
    echo "  ${BUILD_CONTEXT}"
fi

echo "Dockerfile: ${INPUT_DOCKERFILE}"
echo "Build arguments: ${BUILD_ARGS}"
echo "-----------------------------------------------------"

# Build and push image
echo "Starting build job on ACR..."
if [[ -n "${INPUT_GIT_ACCESS_TOKEN:-}" ]]; then
    # Git URL build
    az acr build \
        -r "${INPUT_REGISTRY}" \
        ${BUILD_ARGS} \
        -f "${INPUT_DOCKERFILE}" \
        -t "${INPUT_REPOSITORY,,}${IMAGE_PART}:${INPUT_TAG}" \
        "${BUILD_CONTEXT}"
else
    # Local context build
    az acr build \
        -r "${INPUT_REGISTRY}" \
        ${BUILD_ARGS} \
        -f "${INPUT_FOLDER}/${INPUT_DOCKERFILE}" \
        -t "${INPUT_REPOSITORY,,}${IMAGE_PART}:${INPUT_TAG}" \
        "${BUILD_CONTEXT}"
fi

# --- Set Action Outputs ---
echo "ci_repository_name=${CI_REPOSITORY_NAME}" >> "$GITHUB_OUTPUT"
echo "ci_action_ref_name=${CI_ACTION_REF_NAME}" >> "$GITHUB_OUTPUT"
echo "node_version=${NODE_VERSION}" >> "$GITHUB_OUTPUT"
