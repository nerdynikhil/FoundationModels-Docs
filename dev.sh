#!/bin/bash

# Foundation Models Documentation Development Script

echo "🚀 Foundation Models Documentation Development"
echo "=============================================="

case "$1" in
    "start")
        echo "Starting development server..."
        npm start
        ;;
    "build")
        echo "Building for production..."
        npm run build
        ;;
    "serve")
        echo "Serving built site..."
        npm run serve
        ;;
    "clean")
        echo "Cleaning build artifacts..."
        rm -rf build/
        rm -rf .docusaurus/
        ;;
    "install")
        echo "Installing dependencies..."
        npm install
        ;;
    "deploy")
        echo "Deploying to GitHub Pages..."
        npm run deploy
        ;;
    "sync")
        echo "Syncing documentation from main project..."
        cp -r ../FoundationModels-Examples/docs/* ./docs/
        echo "✅ Documentation synced!"
        ;;
    *)
        echo "Usage: $0 {start|build|serve|clean|install|deploy|sync}"
        echo ""
        echo "Commands:"
        echo "  start   - Start development server"
        echo "  build   - Build for production"
        echo "  serve   - Serve built site"
        echo "  clean   - Clean build artifacts"
        echo "  install - Install dependencies"
        echo "  deploy  - Deploy to GitHub Pages"
        echo "  sync    - Sync docs from main project"
        echo ""
        echo "The development server will be available at: http://localhost:3000"
        ;;
esac 