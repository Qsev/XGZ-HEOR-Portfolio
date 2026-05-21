#!/bin/bash

# Deploy script for HEOR Technical Portfolio
#
# Usage:
#   ./deploy.sh "commit message"           — commit & push only
#   ./deploy.sh --render "commit message"  — render site first, then commit & push

set -e

RENDER=false
if [ "$1" == "--render" ]; then
  RENDER=true
  MSG=${2:-"Update portfolio content"}
else
  MSG=${1:-"Update portfolio content"}
fi

if [ "$RENDER" = true ]; then
  echo "🔨 Rendering Quarto site (changed files only)..."
  quarto render
fi

echo "📦 Staging changes..."
git add -A

echo "💾 Committing: $MSG"
git commit -m "$MSG"

echo "🚀 Pushing to GitHub..."
git push origin main

echo "✅ Done! Site will update at xgzhang.com in ~1 minute."
