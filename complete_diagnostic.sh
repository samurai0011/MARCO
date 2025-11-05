#!/bin/bash

# VK Uploader Pro - Complete Diagnostic and Fix Script
# This script will identify and fix all remaining issues

set -e

echo "🔍 VK Uploader Pro - Complete Diagnostic and Fix"
echo "================================================="

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_status() { echo -e "${BLUE}[INFO]${NC} $1"; }
print_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Navigate to project
cd /root/vk-uploader-pro-2
print_status "Working in: $(pwd)"

# Step 1: Stop service
print_status "Stopping service..."
systemctl stop vk-uploader-pro.service 2>/dev/null || true

# Step 2: Check main.py for issues
print_status "Checking main.py for issues..."

# Check if the registration line was added correctly
if grep -q "auth.register_auth_handlers(bot)" main.py; then
    print_success "Auth handler registration found in main.py"
else
    print_warning "Auth handler registration not found, adding it..."
    sed -i '/bot = Client(/a\\n# Register auth handlers\nauth.register_auth_handlers(bot)' main.py
fi

# Step 3: Test main.py compilation
print_status "Testing main.py compilation..."
if /root/vk-uploader-pro-2/venv/bin/python -m py_compile main.py 2>/dev/null; then
    print_success "main.py compiles successfully!"
else
    print_error "main.py has compilation errors"
    print_status "Checking syntax errors..."
    /root/vk-uploader-pro-2/venv/bin/python -m py_compile main.py
    exit 1
fi

# Step 4: Test main.py execution (dry run)
print_status "Testing main.py execution (dry run)..."
timeout 10 /root/vk-uploader-pro-2/venv/bin/python main.py 2>&1 | head -20 || true

# Step 5: Check for missing dependencies
print_status "Checking for missing dependencies..."
missing_deps=()

# Check if yt-dlp is available
if ! /root/vk-uploader-pro-2/venv/bin/python -c "import yt_dlp" 2>/dev/null; then
    missing_deps+=("yt-dlp")
fi

# Check if bento4 is available
if ! command -v mp4decrypt &> /dev/null; then
    missing_deps+=("bento4")
fi

if [ ${#missing_deps[@]} -gt 0 ]; then
    print_warning "Missing dependencies: ${missing_deps[*]}"
    print_status "Installing missing dependencies..."
    
    # Install yt-dlp in venv
    if [[ " ${missing_deps[*]} " =~ " yt-dlp " ]]; then
        /root/vk-uploader-pro-2/venv/bin/pip install yt-dlp
        print_success "yt-dlp installed"
    fi
    
    # Install bento4 system-wide
    if [[ " ${missing_deps[*]} " =~ " bento4 " ]]; then
        print_status "Installing bento4..."
        wget -q https://www.bok.net/Bento4/binaries/Bento4-SDK-1-6-0-640.x86_64-unknown-linux.zip
        unzip -q Bento4-SDK-1-6-0-640.x86_64-unknown-linux.zip
        cp Bento4-SDK-1-6-0-640.x86_64-unknown-linux/bin/* /usr/local/bin/
        chmod +x /usr/local/bin/mp4*
        print_success "bento4 installed"
    fi
else
    print_success "All dependencies are available"
fi

# Step 6: Check systemd service file
print_status "Checking systemd service file..."
if [ -f "/etc/systemd/system/vk-uploader-pro.service" ]; then
    print_success "Service file exists"
    
    # Check if service file has correct paths
    if grep -q "/root/vk-uploader-pro-2/venv/bin/python" /etc/systemd/system/vk-uploader-pro.service; then
        print_success "Service file has correct Python path"
    else
        print_warning "Service file may have incorrect Python path"
        print_status "Recreating service file..."
        
        cat > /etc/systemd/system/vk-uploader-pro.service << 'EOF'
[Unit]
Description=VK Uploader Pro Telegram Bot
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/root/vk-uploader-pro-2
Environment=PATH=/root/vk-uploader-pro-2/venv/bin:/usr/local/bin:/usr/bin:/bin
ExecStart=/root/vk-uploader-pro-2/venv/bin/python main.py
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF
        print_success "Service file recreated"
    fi
else
    print_error "Service file not found"
    exit 1
fi

# Step 7: Check file permissions
print_status "Checking file permissions..."
chmod +x /root/vk-uploader-pro-2/venv/bin/python
chmod 644 /root/vk-uploader-pro-2/main.py
chmod 644 /root/vk-uploader-pro-2/auth.py
print_success "File permissions set"

# Step 8: Test the exact command that systemd will run
print_status "Testing exact systemd command..."
cd /root/vk-uploader-pro-2
timeout 15 /root/vk-uploader-pro-2/venv/bin/python main.py 2>&1 | head -30 || true

# Step 9: Reload and start service
print_status "Reloading systemd..."
systemctl daemon-reload

print_status "Starting service..."
systemctl start vk-uploader-pro.service

# Step 10: Check status
print_status "Checking service status..."
sleep 5

if systemctl is-active --quiet vk-uploader-pro.service; then
    print_success "🎉 Service is running successfully!"
    echo ""
    print_status "Service Status:"
    systemctl status vk-uploader-pro.service --no-pager -l | head -15
    echo ""
    print_success "✅ Bot is now active and ready to use!"
    print_status "Test your bot by sending /start command"
else
    print_error "❌ Service failed to start"
    echo ""
    print_status "Recent logs:"
    journalctl -u vk-uploader-pro.service --no-pager -l --since "2 minutes ago" | tail -30
    echo ""
    print_status "Checking if there are any Python errors..."
    timeout 10 /root/vk-uploader-pro-2/venv/bin/python main.py 2>&1 | head -50 || true
fi

echo ""
echo "🔧 Diagnostic completed!"
echo "📝 If issues persist, check the logs above for specific error messages"
