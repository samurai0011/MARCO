#!/bin/bash

# Simple fix to restore main.py and start the bot
cd /root/vk-uploader-pro-2

echo "🔧 Restoring main.py and starting bot..."

# Stop service
systemctl stop vk-uploader-pro.service 2>/dev/null || true

# Restore main.py from backup
if [ -f "main.py.backup" ]; then
    cp main.py.backup main.py
    echo "✅ Restored main.py from backup"
else
    echo "❌ No backup found, need to fix manually"
    exit 1
fi

# Remove any incorrectly placed auth registration lines
sed -i '/auth.register_auth_handlers(bot)/d' main.py
sed -i '/# Register auth handlers/d' main.py

# Add auth registration in the correct place - after bot creation
# Find the line with "in_memory=True" and add after it
sed -i '/in_memory=True/a\\n# Register auth handlers\nauth.register_auth_handlers(bot)' main.py

# Test syntax
echo "🧪 Testing syntax..."
if /root/vk-uploader-pro-2/venv/bin/python -m py_compile main.py 2>/dev/null; then
    echo "✅ Syntax is correct!"
else
    echo "❌ Syntax error:"
    /root/vk-uploader-pro-2/venv/bin/python -m py_compile main.py
    exit 1
fi

# Test imports
echo "🧪 Testing imports..."
if /root/vk-uploader-pro-2/venv/bin/python -c "import auth; print('✅ auth.py OK')" 2>/dev/null; then
    echo "✅ Imports work!"
else
    echo "❌ Import failed"
    exit 1
fi

# Start the service
echo "🚀 Starting service..."
systemctl daemon-reload
systemctl start vk-uploader-pro.service

# Check status
echo "📊 Checking status..."
sleep 3

if systemctl is-active --quiet vk-uploader-pro.service; then
    echo "🎉 Bot is running successfully!"
    systemctl status vk-uploader-pro.service --no-pager -l | head -10
else
    echo "❌ Service failed to start"
    echo "📋 Recent logs:"
    journalctl -u vk-uploader-pro.service --no-pager -l --since "2 minutes ago" | tail -20
fi

echo "✅ Fix completed!"
