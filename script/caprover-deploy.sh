#!/bin/bash
# Caprover deployment helper script

set -e

echo "🚀 New Internet - Caprover Deployment"
echo "======================================"
echo ""

# Check if caprover CLI is installed
if ! command -v caprover &> /dev/null; then
    echo "❌ Caprover CLI not found. Installing..."
    npm install -g caprover
fi

# Check if logged in (will prompt if not)
echo "📡 Checking Caprover connection..."
caprover list

# App name
APP_NAME="newinternet"

# Check if app exists
if ! caprover list | grep -q "$APP_NAME"; then
    echo ""
    echo "📦 App '$APP_NAME' not found. Creating..."
    caprover apps:create "$APP_NAME"
    
    echo ""
    echo "⚠️  IMPORTANT: Configure these environment variables in Caprover UI:"
    echo ""
    echo "   RAILS_ENV=production"
    echo "   SECRET_KEY_BASE=$(openssl rand -hex 64)"
    echo "   WEBAUTHN_ORIGIN=https://your-domain.com"
    echo "   WEBAUTHN_RP_ID=your-domain.com"
    echo ""
    echo "Press Enter when environment variables are configured..."
    read
fi

# Deploy
echo ""
echo "🔨 Building and deploying..."
caprover deploy

echo ""
echo "✅ Deployment complete!"
echo ""
echo "🔍 Next steps:"
echo "   1. Enable HTTPS in Caprover UI"
echo "   2. Run migrations: caprover exec $APP_NAME"
echo "      Then: bin/rails db:migrate"
echo "   3. Visit your app and create admin account"
echo ""
