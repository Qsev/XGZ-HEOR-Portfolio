#!/bin/bash

# Deploy script for HEOR Technical Portfolio
# Usage: ./deploy.sh "commit message"

set -e

MSG=${1:-"Update portfolio content"}

echo "🔨 Rendering Quarto site..."
quarto render

echo "📦 Staging changes..."
git add -A

echo "💾 Committing: $MSG"
git commit -m "$MSG"

echo "🚀 Pushing to GitHub..."
git push origin main

echo "✅ Done! Site will update at xgzhang.com in ~1 minute."
