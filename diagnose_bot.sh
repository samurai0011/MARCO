#!/bin/bash

echo "==============================================="
echo "🔍 VK Uploader Pro - Complete Bot Diagnostics"
echo "==============================================="
echo ""

# Check systemd service status
echo "📋 1. Systemd Service Status:"
echo "----------------------------------------"
systemctl status vk-uploader-pro.service --no-pager -l
echo ""

# Check if process is running
echo "📋 2. Process Check:"
echo "----------------------------------------"
ps aux | grep -E "python.*main.py|vk-uploader" | grep -v grep
echo ""

# Check logs
echo "📋 3. Recent Service Logs:"
echo "----------------------------------------"
journalctl -u vk-uploader-pro.service -n 50 --no-pager
echo ""

# Check if bot can connect to Telegram
echo "📋 4. Testing Bot Token with Telegram API:"
echo "----------------------------------------"
cd /root/vk-uploader-pro-2
source venv/bin/activate

# Extract bot token from vars.py
BOT_TOKEN=$(python3 -c "import sys; sys.path.insert(0, '/root/vk-uploader-pro-2'); from vars import BOT_TOKEN; print(BOT_TOKEN)")
echo "Bot Token: ${BOT_TOKEN:0:10}...${BOT_TOKEN: -5}"

# Test getMe
echo ""
echo "Testing getMe API:"
curl -s "https://api.telegram.org/bot${BOT_TOKEN}/getMe" | python3 -m json.tool
echo ""

# Test getUpdates
echo "Testing getUpdates (last 5 updates):"
curl -s "https://api.telegram.org/bot${BOT_TOKEN}/getUpdates?limit=5" | python3 -m json.tool
echo ""

# Check Python syntax
echo "📋 5. Python Syntax Check:"
echo "----------------------------------------"
python3 -m py_compile main.py 2>&1
if [ $? -eq 0 ]; then
    echo "✅ main.py syntax is valid"
else
    echo "❌ main.py has syntax errors"
fi

python3 -m py_compile auth.py 2>&1
if [ $? -eq 0 ]; then
    echo "✅ auth.py syntax is valid"
else
    echo "❌ auth.py has syntax errors"
fi
echo ""

# Check MongoDB connection
echo "📋 6. MongoDB Connection Test:"
echo "----------------------------------------"
python3 -c "
import sys
sys.path.insert(0, '/root/vk-uploader-pro-2')
try:
    from vars import DATABASE_URL
    print(f'Database URL configured: {DATABASE_URL[:20]}...{DATABASE_URL[-10:]}')
    from db import db
    print('✅ Database connection successful')
except Exception as e:
    print(f'❌ Database connection failed: {e}')
"
echo ""

# Check required dependencies
echo "📋 7. Required Dependencies:"
echo "----------------------------------------"
pip list | grep -E "pyrogram|motor|pymongo|yt-dlp|aiohttp|requests"
echo ""

# Check network connectivity
echo "📋 8. Network Connectivity:"
echo "----------------------------------------"
echo "Telegram API:"
curl -s -o /dev/null -w "%{http_code}" https://api.telegram.org/
echo ""
echo "MongoDB (if using Atlas):"
curl -s -o /dev/null -w "%{http_code}" https://cloud.mongodb.com/
echo ""

# Try to run bot manually (5 seconds only)
echo "📋 9. Manual Bot Test (5 seconds):"
echo "----------------------------------------"
timeout 5 python3 main.py 2>&1 || echo "Bot stopped after 5 seconds (this is normal for testing)"
echo ""

# Check vars.py configuration
echo "📋 10. Configuration Check:"
echo "----------------------------------------"
python3 -c "
import sys
sys.path.insert(0, '/root/vk-uploader-pro-2')
from vars import API_ID, API_HASH, BOT_TOKEN, DATABASE_URL, OWNER_ID, ADMINS
print(f'API_ID: {API_ID}')
print(f'API_HASH: {API_HASH[:10]}...{API_HASH[-5:]}')
print(f'BOT_TOKEN: {BOT_TOKEN[:10]}...{BOT_TOKEN[-5:]}')
print(f'DATABASE_URL: {DATABASE_URL[:20]}...{DATABASE_URL[-10:]}')
print(f'OWNER_ID: {OWNER_ID}')
print(f'ADMINS: {ADMINS}')
"
echo ""

# Check file permissions
echo "📋 11. File Permissions:"
echo "----------------------------------------"
ls -la /root/vk-uploader-pro-2/*.py | head -10
echo ""

# Check auth handler registration
echo "📋 12. Auth Handler Registration Check:"
echo "----------------------------------------"
echo "Checking if auth.register_auth_handlers(bot) is in main.py:"
grep -n "auth.register_auth_handlers" main.py
echo ""
echo "Checking if register_auth_handlers function exists in auth.py:"
grep -n "def register_auth_handlers" auth.py
echo ""

echo "==============================================="
echo "✅ Diagnostics Complete!"
echo "==============================================="
echo ""
echo "📝 Next Steps:"
echo "1. Check the service status above"
echo "2. Look for any Python errors in the logs"
echo "3. Verify bot token is working with Telegram"
echo "4. Check if MongoDB connection is successful"
echo ""

