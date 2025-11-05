#!/bin/bash

echo "==============================================="
echo "🔧 Fixing VK Uploader Pro Service"
echo "==============================================="
echo ""

# Stop the failing service
echo "⏹️  Stopping service..."
systemctl stop vk-uploader-pro.service

# Create the correct service file
echo "📝 Creating correct service file..."
cat > /etc/systemd/system/vk-uploader-pro.service << 'EOF'
[Unit]
Description=VK Uploader Pro Telegram Bot
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/root/vk-uploader-pro-2
ExecStart=/bin/bash -c 'cd /root/vk-uploader-pro-2 && source venv/bin/activate && python main.py'
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

echo "✅ Service file created!"
echo ""

# Reload systemd
echo "🔄 Reloading systemd..."
systemctl daemon-reload

# Enable service
echo "✅ Enabling service..."
systemctl enable vk-uploader-pro.service

# Start service
echo "🚀 Starting service..."
systemctl start vk-uploader-pro.service

# Wait a bit for startup
sleep 3

# Check status
echo ""
echo "==============================================="
echo "📊 Service Status:"
echo "==============================================="
systemctl status vk-uploader-pro.service --no-pager -l

echo ""
echo "==============================================="
echo "📋 Recent Logs:"
echo "==============================================="
journalctl -u vk-uploader-pro.service -n 20 --no-pager

echo ""
echo "==============================================="
echo "✅ Fix Complete!"
echo "==============================================="
echo ""
echo "📝 To check logs: journalctl -u vk-uploader-pro.service -f"
echo "📝 To restart: systemctl restart vk-uploader-pro.service"
echo "📝 To stop: systemctl stop vk-uploader-pro.service"
echo ""

