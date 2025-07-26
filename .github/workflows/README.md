# GitHub Actions Setup

This workflow automatically builds and pushes the Docker image to Docker Hub when changes are pushed to the main branch or when pull requests are created.

## Required Secrets

To use this workflow, you need to configure the following secrets in your GitHub repository:

### 1. DOCKER_USERNAME
Your Docker Hub username.

### 2. DOCKER_ACCESS_TOKEN
Your Docker Hub access token (recommended) or password.

## How to Set Up Secrets

1. Go to your GitHub repository
2. Click on "Settings" tab
3. In the left sidebar, click on "Secrets and variables" → "Actions"
4. Click "New repository secret"
5. Add the following secrets:
   - **Name**: `DOCKER_USERNAME`
   - **Value**: Your Docker Hub username
   
   - **Name**: `DOCKER_ACCESS_TOKEN`
   - **Value**: Your Docker Hub access token

## Docker Hub Access Token Setup

For security, use a Docker Hub access token instead of your password:

1. Go to [Docker Hub](https://hub.docker.com/)
2. Click on your username → "Account Settings"
3. Go to "Security" → "New Access Token"
4. Give it a name (e.g., "GitHub Actions")
5. Copy the token and use it as the `DOCKER_ACCESS_TOKEN` secret

## Workflow Behavior

- **Push to main/master**: Builds and pushes the image to Docker Hub
- **Pull Request**: Builds the image but doesn't push (for testing)
- **Tags**: Automatically creates tags based on:
  - Branch name
  - Git SHA
  - Semantic version tags (if you use git tags)

## Image Tags

The workflow creates the following tags:
- `latest` (for main branch)
- `main` (for main branch)
- `sha-<commit-hash>` (for specific commits)
- Semantic version tags (if you tag releases with v1.0.0, etc.) 