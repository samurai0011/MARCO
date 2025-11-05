#!/bin/bash

# Complete fix for main.py - restore from original backup and properly configure
cd /root/vk-uploader-pro-2

echo "🔧 Complete main.py fix and bot startup..."

# Stop service
echo "⏹️  Stopping service..."
systemctl stop vk-uploader-pro.service 2>/dev/null || true

# Check what we have
echo "📋 Checking current files..."
ls -la *.backup* 2>/dev/null || true

# Find the best backup
if [ -f "main.py.backup.backup" ]; then
    echo "✅ Using main.py.backup.backup"
    cp main.py.backup.backup main.py
elif [ -f "main.py.backup" ]; then
    echo "✅ Using main.py.backup"
    cp main.py.backup main.py
else
    echo "❌ No backup found"
    echo "Let's check the main.py around bot creation..."
    sed -n '80,95p' main.py
    exit 1
fi

# Now clean up any auth registration lines that might have been added
echo "🧹 Cleaning up incorrect auth registration lines..."
sed -i '/auth.register_auth_handlers(bot)/d' main.py
sed -i '/# Register auth handlers/d' main.py

# Check the bot creation section
echo "📋 Checking bot creation section..."
sed -n '80,95p' main.py

# Now we need to add auth registration AFTER bot creation but BEFORE any handlers
# Let's find where the bot is created and add after the closing parenthesis
echo "➕ Adding auth registration in correct location..."

# First, let's see if there's a line with "Register command handlers" comment
if grep -q "# Register command handlers" main.py; then
    # Add auth registration before this line
    sed -i '/# Register command handlers/i\# Register auth handlers\nauth.register_auth_handlers(bot)\n' main.py
    echo "✅ Added auth registration before command handlers"
else
    # Add after the register_clean_handler line
    sed -i '/register_clean_handler(bot)/a\\n# Register auth handlers\nauth.register_auth_handlers(bot)' main.py
    echo "✅ Added auth registration after clean handler"
fi

# Check the section again
echo "📋 Verifying changes..."
sed -n '90,100p' main.py

# Test Python syntax
echo "🧪 Testing Python syntax..."
if /root/vk-uploader-pro-2/venv/bin/python -m py_compile main.py; then
    echo "✅ Syntax is correct!"
else
    echo "❌ Syntax error detected:"
    /root/vk-uploader-pro-2/venv/bin/python -m py_compile main.py
    echo ""
    echo "Let's try a different approach - run bot without systemd first"
    echo "Running bot directly to see actual error..."
    timeout 10 /root/vk-uploader-pro-2/venv/bin/python main.py 2>&1 | head -50
    exit 1
fi

# Test imports
echo "🧪 Testing imports..."
/root/vk-uploader-pro-2/venv/bin/python -c "import main" 2>&1 | head -20

# Try running bot briefly to see if it initializes
echo "🧪 Testing bot initialization..."
timeout 5 /root/vk-uploader-pro-2/venv/bin/python main.py 2>&1 | head -30 &
sleep 3
pkill -f "python main.py" 2>/dev/null || true

# If we got here, start the service
echo "🚀 Starting service..."
systemctl daemon-reload
systemctl start vk-uploader-pro.service

# Check status
echo "📊 Checking status..."
sleep 5

if systemctl is-active --quiet vk-uploader-pro.service; then
    echo "🎉 Service is running!"
    systemctl status vk-uploader-pro.service --no-pager -l | head -15
else
    echo "❌ Service failed"
    echo "📋 Checking logs..."
    journalctl -u vk-uploader-pro.service -n 30 --no-pager
fi

echo ""
echo "✅ Fix completed!"
echo "If still failing, run: journalctl -u vk-uploader-pro.service -f"
