#!/bin/bash

# Pharmory iOS App Setup Script
# Flutter-only setup (no backend required)

echo "📱 Setting up Pharmory iOS app..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if we're in the right directory
if [ ! -f "pubspec.yaml" ]; then
    print_error "Please run this script from the pharmory project root directory"
    exit 1
fi

print_status "Checking system requirements..."

# Check for Flutter
if ! command -v flutter &> /dev/null; then
    print_error "Flutter is required but not installed"
    print_status "Please install Flutter from https://flutter.dev/docs/get-started/install"
    exit 1
fi

print_success "Flutter found: $(flutter --version | head -1)"

# Check iOS development setup (only on macOS)
if [[ "$OSTYPE" != "darwin"* ]]; then
    print_error "This app is designed for iOS development on macOS"
    exit 1
fi

print_status "Checking iOS development environment..."

# Check for Xcode
if ! command -v xcodebuild &> /dev/null; then
    print_warning "Xcode not found. iOS development requires Xcode."
    print_status "Please install Xcode from the App Store"
else
    print_success "Xcode found: $(xcodebuild -version | head -1)"
fi

# Check iOS simulator
if xcrun simctl list devices | grep -q "iPhone"; then
    print_success "iOS simulators available"
else
    print_warning "No iOS simulators found"
    print_status "Please install iOS simulators via Xcode"
fi

# Setup Flutter app
print_status "Setting up Flutter dependencies..."

# Clean previous builds
flutter clean

# Get Flutter dependencies
print_status "Getting Flutter dependencies..."
flutter pub get

if [ $? -eq 0 ]; then
    print_success "Flutter dependencies installed successfully"
else
    print_error "Failed to install Flutter dependencies"
    exit 1
fi

# Check Flutter setup
print_status "Running Flutter doctor..."
flutter doctor

# Configuration check
print_status "Checking API configuration..."

CONFIG_FILE="lib/config/app_config.dart"
if [ -f "$CONFIG_FILE" ]; then
    if grep -q "YOUR_OPENAI_API_KEY_HERE" "$CONFIG_FILE"; then
        print_warning "OpenAI API key not configured in $CONFIG_FILE"
        NEEDS_CONFIG=true
    fi
    
    if grep -q "YOUR_SUPABASE_URL_HERE" "$CONFIG_FILE"; then
        print_warning "Supabase URL not configured in $CONFIG_FILE"
        NEEDS_CONFIG=true
    fi
    
    if [ "$NEEDS_CONFIG" = true ]; then
        print_warning "Please edit $CONFIG_FILE with your API keys"
    else
        print_success "API configuration appears to be set"
    fi
else
    print_error "Configuration file not found: $CONFIG_FILE"
fi

# Final checks
print_status "Running final checks..."

# Test Flutter build
print_status "Testing iOS build..."
flutter build ios --no-codesign --simulator

if [ $? -eq 0 ]; then
    print_success "iOS build successful"
else
    print_warning "iOS build had issues - check dependencies"
fi

print_success "Setup completed!"

echo ""
echo "📋 Next steps:"
echo ""
echo "1. Configure your API keys in lib/config/app_config.dart:"
echo "   - OpenAI API Key (required for AI features)"
echo "   - Supabase URL and Key (required for database)"
echo ""
echo "2. Set up Supabase database:"
echo "   - Create account at https://supabase.com"
echo "   - Create new project"
echo "   - Run database/supabase_setup.sql in SQL editor"
echo ""
echo "3. Start the iOS simulator:"
echo "   open -a Simulator"
echo ""
echo "4. Run the Flutter app:"
echo "   flutter run"
echo ""
echo "📖 How to get API keys:"
echo ""
echo "🤖 OpenAI API Key:"
echo "   1. Go to https://platform.openai.com/"
echo "   2. Sign up/Login"
echo "   3. Go to API Keys section"
echo "   4. Create new secret key"
echo ""
echo "🗄️ Supabase:"
echo "   1. Go to https://supabase.com/"
echo "   2. Create new project"
echo "   3. Go to Settings > API"
echo "   4. Copy URL and anon key"
echo ""
echo "🎉 Happy coding with Pharmory iOS app!"