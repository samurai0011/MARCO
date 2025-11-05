#!/bin/bash

# VK Uploader Pro - Complete Bot Fix Script
# Run this script on your Ubuntu server to fix all issues

set -e

echo "🔧 VK Uploader Pro - Complete Bot Fix"
echo "======================================"

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

# Step 2: Backup files
print_status "Creating backups..."
cp auth.py auth.py.backup.$(date +%Y%m%d_%H%M%S) 2>/dev/null || true
cp main.py main.py.backup.$(date +%Y%m%d_%H%M%S) 2>/dev/null || true

# Step 3: Fix auth.py completely
print_status "Creating clean auth.py..."
cat > auth.py << 'EOF'
from pyrogram import Client, filters
from pyrogram.types import Message
from pyrogram.handlers import MessageHandler
from db import get_user, add_user, remove_user, get_all_users, update_user_plan
import vars

async def is_authorized(user_id: int) -> bool:
    """Check if user is authorized"""
    try:
        user = await get_user(user_id)
        return user is not None
    except:
        return False

async def add_user_cmd(client: Client, message: Message):
    """Add user command handler"""
    if message.from_user.id != vars.OWNER_ID:
        await message.reply_text("❌ You are not authorized to use this command.")
        return
    
    try:
        if message.reply_to_message:
            user_id = message.reply_to_message.from_user.id
        else:
            text = message.text.split()
            if len(text) < 2:
                await message.reply_text("❌ Please provide a user ID or reply to a user's message.")
                return
            user_id = int(text[1])
        
        await add_user(user_id, "premium", 30)
        await message.reply_text(f"✅ User {user_id} has been added successfully!")
        
    except ValueError:
        await message.reply_text("❌ Invalid user ID. Please provide a valid number.")
    except Exception as e:
        await message.reply_text(f"❌ Error adding user: {str(e)}")

async def remove_user_cmd(client: Client, message: Message):
    """Remove user command handler"""
    if message.from_user.id != vars.OWNER_ID:
        await message.reply_text("❌ You are not authorized to use this command.")
        return
    
    try:
        if message.reply_to_message:
            user_id = message.reply_to_message.from_user.id
        else:
            text = message.text.split()
            if len(text) < 2:
                await message.reply_text("❌ Please provide a user ID or reply to a user's message.")
                return
            user_id = int(text[1])
        
        await remove_user(user_id)
        await message.reply_text(f"✅ User {user_id} has been removed successfully!")
        
    except ValueError:
        await message.reply_text("❌ Invalid user ID. Please provide a valid number.")
    except Exception as e:
        await message.reply_text(f"❌ Error removing user: {str(e)}")

async def list_users_cmd(client: Client, message: Message):
    """List users command handler"""
    if message.from_user.id != vars.OWNER_ID:
        await message.reply_text("❌ You are not authorized to use this command.")
        return
    
    try:
        users = await get_all_users()
        if not users:
            await message.reply_text("📝 No users found.")
            return
        
        text = "👥 **Authorized Users:**\n\n"
        for user in users:
            text += f"🆔 **User ID:** `{user['user_id']}`\n"
            text += f"📋 **Plan:** {user.get('plan', 'free')}\n"
            text += f"📅 **Expires:** {user.get('expires_at', 'Never')}\n"
            text += f"📊 **Downloads:** {user.get('downloads', 0)}\n\n"
        
        await message.reply_text(text)
        
    except Exception as e:
        await message.reply_text(f"❌ Error listing users: {str(e)}")

async def my_plan_cmd(client: Client, message: Message):
    """My plan command handler"""
    user_id = message.from_user.id
    
    try:
        user = await get_user(user_id)
        if not user:
            await message.reply_text("❌ You are not authorized. Contact admin to get access.")
            return
        
        plan = user.get('plan', 'free')
        downloads = user.get('downloads', 0)
        expires_at = user.get('expires_at', 'Never')
        
        text = f"📋 **Your Plan Information:**\n\n"
        text += f"🆔 **User ID:** `{user_id}`\n"
        text += f"📋 **Plan:** {plan}\n"
        text += f"📊 **Downloads Used:** {downloads}\n"
        text += f"📅 **Expires:** {expires_at}\n"
        
        await message.reply_text(text)
        
    except Exception as e:
        await message.reply_text(f"❌ Error getting plan info: {str(e)}")

def register_auth_handlers(bot):
    """Register authentication handlers with the bot"""
    bot.add_handler(MessageHandler(add_user_cmd, filters.command("add") & filters.private))
    bot.add_handler(MessageHandler(remove_user_cmd, filters.command("remove") & filters.private))
    bot.add_handler(MessageHandler(list_users_cmd, filters.command("users") & filters.private))
    bot.add_handler(MessageHandler(my_plan_cmd, filters.command("plan") & filters.private))
EOF

print_success "auth.py created successfully!"

# Step 4: Fix main.py
print_status "Fixing main.py..."

# Remove the problematic line
sed -i '/auth.register_auth_handlers(app)/d' main.py

# Find where bot is created and add registration after it
if grep -q "bot = Client(" main.py; then
    # Add registration after bot creation
    sed -i '/bot = Client(/a\\n# Register auth handlers\nauth.register_auth_handlers(bot)' main.py
    print_success "Added auth handler registration to main.py"
else
    print_error "Could not find bot creation in main.py"
    exit 1
fi

# Step 5: Test imports
print_status "Testing Python imports..."
if /root/vk-uploader-pro-2/venv/bin/python -c "import auth; print('✅ auth.py imports OK')" 2>/dev/null; then
    print_success "auth.py imports successfully!"
else
    print_error "auth.py import failed"
    exit 1
fi

# Step 6: Test main.py compilation
print_status "Testing main.py compilation..."
if /root/vk-uploader-pro-2/venv/bin/python -m py_compile main.py 2>/dev/null; then
    print_success "main.py compiles successfully!"
else
    print_error "main.py compilation failed"
    exit 1
fi

# Step 7: Reload and start service
print_status "Reloading systemd..."
systemctl daemon-reload

print_status "Starting service..."
systemctl start vk-uploader-pro.service

# Step 8: Check status
print_status "Checking service status..."
sleep 5

if systemctl is-active --quiet vk-uploader-pro.service; then
    print_success "🎉 Service is running successfully!"
    echo ""
    echo "📊 Service Status:"
    systemctl status vk-uploader-pro.service --no-pager -l | head -10
    echo ""
    print_success "✅ Bot is now active and ready to use!"
    print_status "Test your bot by sending /start command"
else
    print_error "❌ Service failed to start"
    echo ""
    print_status "Recent logs:"
    journalctl -u vk-uploader-pro.service --no-pager -l --since "2 minutes ago" | tail -20
fi

echo ""
echo "🔧 Fix completed!"
echo "📝 Backup files created with timestamp"
echo "🚀 Bot should now be working properly"
