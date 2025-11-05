#!/bin/bash

# Fix the main.py syntax error
cd /root/vk-uploader-pro-2

echo "🔧 Fixing main.py syntax error..."

# Stop service first
systemctl stop vk-uploader-pro.service 2>/dev/null || true

# Backup current main.py
cp main.py main.py.backup.$(date +%Y%m%d_%H%M%S)

# Remove the incorrectly placed auth registration line
sed -i '/auth.register_auth_handlers(bot)/d' main.py

# Find the correct location - after the bot = Client(...) block ends
# Look for the line after the closing parenthesis of Client()
sed -i '/bot = Client(/,/^)/{ /^)/a\\n# Register auth handlers\nauth.register_auth_handlers(bot)' main.py

# Alternative approach - find the exact line and add after it
# First, let's see what's around line 90
echo "📋 Checking main.py structure around bot creation..."
grep -n -A 10 -B 5 "bot = Client" main.py

# Let's fix this more precisely
# Find the line with the closing parenthesis of the Client() call
line_num=$(grep -n "workers=300" main.py | cut -d: -f1)
if [ ! -z "$line_num" ]; then
    # Add the auth registration after the Client() call
    sed -i "${line_num}a\\n# Register auth handlers\nauth.register_auth_handlers(bot)" main.py
    echo "✅ Added auth registration after line $line_num"
else
    echo "❌ Could not find the correct location"
    exit 1
fi

# Test the syntax
echo "🧪 Testing main.py syntax..."
if /root/vk-uploader-pro-2/venv/bin/python -m py_compile main.py 2>/dev/null; then
    echo "✅ main.py syntax is now correct!"
else
    echo "❌ Still has syntax errors"
    /root/vk-uploader-pro-2/venv/bin/python -m py_compile main.py
    exit 1
fi

# Test the import
echo "🧪 Testing imports..."
if /root/vk-uploader-pro-2/venv/bin/python -c "import auth; print('✅ auth.py OK')" 2>/dev/null; then
    echo "✅ auth.py imports successfully!"
else
    echo "❌ auth.py import failed"
    exit 1
fi

# Reload and start service
echo "🔄 Reloading systemd..."
systemctl daemon-reload

echo "🚀 Starting service..."
systemctl start vk-uploader-pro.service

echo "📊 Checking service status..."
sleep 5

if systemctl is-active --quiet vk-uploader-pro.service; then
    echo "🎉 Service is running successfully!"
    systemctl status vk-uploader-pro.service --no-pager -l | head -10
else
    echo "❌ Service failed to start"
    echo "📋 Recent logs:"
    journalctl -u vk-uploader-pro.service --no-pager -l --since "2 minutes ago" | tail -20
fi

echo "✅ Fix completed!"
