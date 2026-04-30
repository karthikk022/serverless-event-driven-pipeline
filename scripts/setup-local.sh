#!/bin/bash
set -e

echo "🔧 Setting up local development environment..."

# Check prerequisites
echo "Checking prerequisites..."

if ! command -v node &> /dev/null; then
    echo "❌ Node.js is not installed. Please install Node.js 20+."
    exit 1
fi

if ! command -v python3 &> /dev/null; then
    echo "❌ Python 3 is not installed. Please install Python 3.11+."
    exit 1
fi

if ! command -v terraform &> /dev/null; then
    echo "❌ Terraform is not installed. Please install Terraform 1.5+."
    exit 1
fi

if ! command -v aws &> /dev/null; then
    echo "❌ AWS CLI is not installed. Please install AWS CLI v2."
    exit 1
fi

echo "✓ All prerequisites installed"

# Setup Python virtual environment
echo "Setting up Python virtual environment..."
python3 -m venv venv
source venv/bin/activate
pip install -r src/lambda/requirements.txt
pip install pytest moto aws-xray-sdk

# Install Node dependencies
echo "Installing Node dependencies..."
npm install

# Setup pre-commit hooks (optional)
if command -v pre-commit &> /dev/null; then
    pre-commit install
    echo "✓ Pre-commit hooks installed"
fi

echo "🎉 Local development environment ready!"
echo ""
echo "Next steps:"
echo "  1. Configure AWS credentials: aws configure"
echo "  2. Deploy infrastructure: cd terraform && terraform init && terraform apply"
echo "  3. Start dev server: npm run dev"
echo "  4. Run tests: npm run test"
