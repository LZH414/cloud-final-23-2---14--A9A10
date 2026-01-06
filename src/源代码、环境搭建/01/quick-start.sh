#!/bin/bash

echo "=========================================="
echo "Cloud Native Demo - Quick Start"
echo "=========================================="
echo ""

echo "Checking prerequisites..."

# Check Node.js
if ! command -v node &> /dev/null; then
    echo "❌ Node.js not found. Please install Node.js 18+ first."
    echo "   See INSTALL.md for installation instructions."
    exit 1
fi
echo "✓ Node.js $(node --version)"

# Check npm
if ! command -v npm &> /dev/null; then
    echo "❌ npm not found."
    exit 1
fi
echo "✓ npm $(npm --version)"

# Check Docker
if ! command -v docker &> /dev/null; then
    echo "❌ Docker not found. Please install Docker first."
    echo "   See INSTALL.md for installation instructions."
    exit 1
fi
echo "✓ Docker $(docker --version)"

# Check Docker Compose
if ! docker compose version &> /dev/null; then
    echo "❌ Docker Compose not found."
    exit 1
fi
echo "✓ Docker Compose $(docker compose version)"

echo ""
echo "All prerequisites installed!"
echo ""

# Install dependencies
echo "Installing project dependencies..."
npm install

if [ $? -ne 0 ]; then
    echo "❌ Failed to install dependencies"
    exit 1
fi
echo "✓ Dependencies installed"
echo ""

# Run tests
echo "Running tests..."
npm test

if [ $? -ne 0 ]; then
    echo "⚠️  Some tests failed, but continuing..."
else
    echo "✓ All tests passed"
fi
echo ""

# Build Docker image
echo "Building Docker image..."
docker build -t cloud-native-demo:latest .

if [ $? -ne 0 ]; then
    echo "❌ Failed to build Docker image"
    exit 1
fi
echo "✓ Docker image built"
echo ""

# Start with Docker Compose
echo "Starting application with Docker Compose..."
docker-compose up -d

if [ $? -ne 0 ]; then
    echo "❌ Failed to start application"
    exit 1
fi
echo "✓ Application started"
echo ""

# Wait for application to be ready
echo "Waiting for application to be ready..."
sleep 5

# Check if application is running
if curl -s http://localhost:3000/health > /dev/null; then
    echo "✓ Application is healthy"
else
    echo "⚠️  Application health check failed, but it may still be starting..."
fi

echo ""
echo "=========================================="
echo "Setup Complete!"
echo "=========================================="
echo ""
echo "Application is running at:"
echo "  - Main page:    http://localhost:3000"
echo "  - Health check: http://localhost:3000/health"
echo "  - Version info: http://localhost:3000/info"
echo "  - Metrics:      http://localhost:3000/metrics"
echo ""
echo "Useful commands:"
echo "  - View logs:    docker-compose logs -f"
echo "  - Stop app:     docker-compose down"
echo "  - Restart app:  docker-compose restart"
echo ""
echo "For more information, see README.md"
echo ""
