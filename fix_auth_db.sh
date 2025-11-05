#!/bin/bash

# Fix auth.py with correct database usage
cd /root/vk-uploader-pro-2

cat > auth.py << 'EOF'
from pyrogram import Client, filters
from pyrogram.types import Message
from pyrogram.handlers import MessageHandler
from db import db
import vars

async def is_authorized(user_id: int) -> bool:
    """Check if user is authorized"""
    try:
        return db.is_user_authorized(user_id, "ugdevbot")
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
            name = message.reply_to_message.from_user.first_name or "User"
        else:
            text = message.text.split()
            if len(text) < 2:
                await message.reply_text("❌ Please provide a user ID or reply to a user's message.")
                return
            user_id = int(text[1])
            name = text[2] if len(text) > 2 else "User"
        
        # Add user with 30 days premium
        success = db.add_user(user_id, name, 30, "ugdevbot")
        if success:
            await message.reply_text(f"✅ User {user_id} ({name}) has been added successfully!")
        else:
            await message.reply_text(f"❌ Failed to add user {user_id}")
        
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
        
        success = db.remove_user(user_id, "ugdevbot")
        if success:
            await message.reply_text(f"✅ User {user_id} has been removed successfully!")
        else:
            await message.reply_text(f"❌ User {user_id} not found or failed to remove")
        
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
        users = db.list_users("ugdevbot")
        if not users:
            await message.reply_text("📝 No users found.")
            return
        
        text = "👥 **Authorized Users:**\n\n"
        for user in users:
            text += f"🆔 **User ID:** `{user['user_id']}`\n"
            text += f"👤 **Name:** {user.get('name', 'Unknown')}\n"
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
        user_info = db.get_user_expiry_info(user_id, "ugdevbot")
        if not user_info:
            await message.reply_text("❌ You are not authorized. Contact admin to get access.")
            return
        
        plan = user_info.get('plan', 'free')
        downloads = user_info.get('downloads', 0)
        expires_at = user_info.get('expires_at', 'Never')
        name = user_info.get('name', 'Unknown')
        
        text = f"📋 **Your Plan Information:**\n\n"
        text += f"👤 **Name:** {name}\n"
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

echo "✅ Fixed auth.py with correct database usage"

# Test the import
echo "🧪 Testing auth.py import..."
/root/vk-uploader-pro-2/venv/bin/python -c "import auth; print('✅ auth.py imports successfully!')"

# Reload systemd and start service
echo "🔄 Reloading systemd..."
systemctl daemon-reload

echo "🚀 Starting service..."
systemctl start vk-uploader-pro.service

echo "📊 Checking service status..."
sleep 3
systemctl status vk-uploader-pro.service --no-pager -l

echo "✅ Fix completed!"
