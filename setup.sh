#!/bin/bash
# Setup script for cursor-test project
# Creates virtual environment and installs dependencies

set -e  # Exit on error

echo "🚀 Setting up cursor-test development environment..."
echo ""

# Check Python version
PYTHON_CMD=""
if command -v python3 &> /dev/null; then
    PYTHON_CMD="python3"
elif command -v python &> /dev/null; then
    PYTHON_CMD="python"
else
    echo "❌ Error: Python not found. Please install Python 3.8 or higher."
    exit 1
fi

PYTHON_VERSION=$($PYTHON_CMD --version 2>&1 | awk '{print $2}')
echo "✓ Found Python $PYTHON_VERSION"

# Check if python3-venv is available
if ! $PYTHON_CMD -m venv --help &> /dev/null; then
    echo ""
    echo "❌ Error: python3-venv is not installed"
    echo ""
    echo "Please install it with:"
    echo "  sudo apt install python3-venv"
    echo ""
    echo "Then run this script again."
    exit 1
fi

# Create virtual environment
if [ -d "venv" ]; then
    echo "⚠️  Virtual environment already exists"
    read -p "Do you want to recreate it? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "🗑️  Removing old virtual environment..."
        rm -rf venv
    else
        echo "Using existing virtual environment"
    fi
fi

if [ ! -d "venv" ]; then
    echo "📦 Creating virtual environment..."
    $PYTHON_CMD -m venv venv
    echo "✓ Virtual environment created"
fi

# Activate virtual environment
echo "🔌 Activating virtual environment..."
source venv/bin/activate

# Upgrade pip
echo "⬆️  Upgrading pip..."
pip install --upgrade pip -q

# Install dependencies
echo "📚 Installing dependencies..."
pip install -r requirements.txt -q

echo ""
echo "✅ Setup complete!"
echo ""
echo "📝 Next steps:"
echo "  1. Activate the virtual environment:"
echo "     source venv/bin/activate"
echo ""
echo "  2. Copy .env.example to .env and add your GitHub token:"
echo "     cp .env.example .env"
echo "     nano .env  # or use your preferred editor"
echo ""
echo "  3. Verify setup:"
echo "     python -c \"from scripts.utils.github_api import GitHubAPI; api = GitHubAPI(); print('✓ Ready!')\""
echo ""
echo "🎉 Happy coding!"

