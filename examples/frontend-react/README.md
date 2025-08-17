# Frontend React Application Template

This is a template for React frontend applications to be used with the Cheetah deployment platform.

## Key Features

- React 18 with modern hooks
- Nginx reverse proxy configuration
- Health check endpoints
- Docker multi-stage builds
- Non-root container execution
- Port 8080 for compatibility

## Important Notes

### Port Configuration
The application runs on port 8080 instead of port 80 to avoid permission issues with non-root containers in Kubernetes.

### Nginx Configuration
The nginx.conf includes:
- Proper error handling
- Health check endpoint
- Static file serving
- History API fallback for SPA routing

### Docker Build
Uses multi-stage build to minimize image size:
1. Build stage: Install dependencies and build React app
2. Production stage: Copy built files to nginx container

## Usage

1. Copy these files to your project
2. Customize the React application as needed
3. Update package.json with your project details
4. The Cheetah deployment scripts will handle the rest

## Health Check

The application provides a health check endpoint at `/health` that returns a simple JSON response.
