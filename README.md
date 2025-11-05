# 🚀 VK Uploader Pro - Advanced Telegram Bot

A powerful Telegram bot designed for downloading and uploading various types of content including DRM-protected videos, PDFs, images, and more. This bot supports batch processing, multiple resolution options, and automated watermarking.

## ✨ Features

### 🎯 Core Functionality
- **DRM Video Download**: Download DRM-protected videos from various platforms
- **Batch Processing**: Process multiple URLs from text files
- **Multi-format Support**: Videos (MP4, MKV, WebM), PDFs, Images (JPG, PNG), Audio files
- **Resolution Options**: Support for 144p, 240p, 360p, 480p, 720p, 1080p
- **Watermarking**: Add custom watermarks to videos
- **Thumbnail Generation**: Automatic thumbnail creation
- **Large File Handling**: Automatic splitting for files >2GB

### 🔧 Advanced Features
- **User Authorization System**: MongoDB-based user management
- **Subscription Management**: Time-based access control
- **Admin Commands**: User management and bot administration
- **Logging System**: Comprehensive error logging and monitoring
- **HTML Generator**: Convert text files to interactive HTML pages
- **Text to TXT Converter**: Convert text to downloadable files
- **Cookie Management**: YouTube cookie support for age-restricted content

### 🌐 Supported Platforms
- **ClassPlus**: DRM video extraction
- **YouTube**: Direct video downloads with cookie support
- **Google Drive**: File downloads
- **Various CDNs**: Akamai, CloudFront, and other CDN networks
- **M3U8 Streams**: HLS video stream processing
- **PDF Sources**: Multiple PDF hosting platforms

## 📋 Prerequisites

### System Requirements
- **Python**: 3.8 or higher
- **FFmpeg**: For video processing
- **Aria2**: For fast downloads
- **MongoDB**: For user management
- **Bento4**: For DRM decryption (mp4decrypt)

### API Requirements
- **Telegram Bot Token**: From [@BotFather](https://t.me/BotFather)
- **Telegram API ID & Hash**: From [my.telegram.org](https://my.telegram.org)
- **MongoDB Atlas**: Cloud database (recommended)

## 🚀 Installation & Setup

### 1. Clone the Repository
```bash
git clone https://github.com/vkmalani9/vk-uploader-pro-2.git
cd vk-uploader-pro-2
```

### 2. Install System Dependencies

#### Ubuntu/Debian:
```bash
sudo apt update
sudo apt install -y python3 python3-pip ffmpeg aria2 wget unzip gcc g++ cmake make libffi-dev
```

#### CentOS/RHEL:
```bash
sudo yum update
sudo yum install -y python3 python3-pip ffmpeg aria2 wget unzip gcc gcc-c++ cmake make libffi-devel
```

### 3. Install Bento4 (for DRM decryption)
```bash
wget https://github.com/axiomatic-systems/Bento4/archive/refs/tags/v1.6.0-639.zip
unzip v1.6.0-639.zip
cd Bento4-1.6.0-639
mkdir cmakebuild && cd cmakebuild
cmake -DCMAKE_BUILD_TYPE=Release ..
make -j$(nproc) mp4decrypt
sudo cp mp4decrypt /usr/local/bin/
```

### 4. Install Python Dependencies
```bash
pip3 install -r thanosbots.txt
pip3 install "yt-dlp[default]"
```

### 5. Environment Configuration
Create a `.env` file or set environment variables:

```bash
# Telegram Configuration
export API_ID="your_api_id"
export API_HASH="your_api_hash"
export BOT_TOKEN="your_bot_token"

# Database Configuration
export DATABASE_URL="mongodb+srv://username:password@cluster.mongodb.net/"
export DATABASE_NAME="VickyUtkarsh"

# Owner Configuration
export OWNER_ID="your_telegram_user_id"
export ADMINS="admin1_id admin2_id"

# Optional Configuration
export CREDIT="Your Bot Name"
export WEB_SERVER="False"
export PORT="8000"
```

### 6. Database Setup
1. Create a MongoDB Atlas account
2. Create a new cluster
3. Get your connection string
4. Update `DATABASE_URL` in your environment variables

## 🐳 Docker Deployment

### Using Docker Compose
```yaml
version: '3.8'
services:
  vk-uploader:
    build: .
    environment:
      - API_ID=${API_ID}
      - API_HASH=${API_HASH}
      - BOT_TOKEN=${BOT_TOKEN}
      - DATABASE_URL=${DATABASE_URL}
      - OWNER_ID=${OWNER_ID}
      - ADMINS=${ADMINS}
    ports:
      - "8000:8000"
    volumes:
      - ./downloads:/app/downloads
    restart: unless-stopped
```

### Build and Run
```bash
docker build -t vk-uploader-pro .
docker run -d --name vk-uploader --env-file .env vk-uploader-pro
```

## ☁️ Cloud Deployment

### Heroku Deployment
1. Fork this repository
2. Create a new Heroku app
3. Add buildpacks:
   - `https://github.com/amivin/aria2-heroku.git`
   - `heroku/python`
   - `https://github.com/jonathanong/heroku-buildpack-ffmpeg-latest.git`
4. Set environment variables in Heroku dashboard
5. Deploy using GitHub integration

### Railway Deployment
1. Connect your GitHub repository
2. Set environment variables
3. Deploy automatically

### Render Deployment
1. Create a new Web Service
2. Connect your repository
3. Set environment variables
4. Deploy

## 🎮 Usage Guide

### Bot Commands

#### User Commands
- `/start` - Start the bot and check authorization
- `/drm` - Upload a text file with URLs for batch processing
- `/plan` - Check your subscription status
- `/id` - Get your Telegram user ID
- `/t2t` - Convert text to TXT file
- `/t2h` - Convert text file to HTML page

#### Admin Commands
- `/add user_id days` - Add user with subscription
- `/remove user_id` - Remove user access
- `/users` - List all users
- `/clean` - Clean downloads and expired users
- `/setlog channel_id` - Set log channel
- `/getlog` - Get current log channel info
- `/cookies` - Upload YouTube cookies
- `/getcookies` - Download current cookies
- `/stop` - Restart the bot

### Text File Format
Create a text file with URLs in this format:
```
Video Name 1: https://example.com/video1.m3u8
Video Name 2: https://example.com/video2.mp4
PDF Document: https://example.com/document.pdf
Image File: https://example.com/image.jpg
```

### Batch Processing Workflow
1. Send `/drm` command
2. Upload your text file
3. Select starting index (1 to total URLs)
4. Enter batch name
5. Choose resolution (144p to 1080p)
6. Set watermark (or use `/d` for none)
7. Add credit name
8. Provide MPD token (if needed)
9. Upload thumbnail (optional)
10. Set target channel ID

## 🔧 Configuration

### Bot Settings
Edit `vars.py` to customize:
- Default thumbnails
- Credit text
- Admin IDs
- Database settings
- API configurations

### Performance Tuning
- Adjust `workers` in bot initialization
- Modify `sleep_threshold` for rate limiting
- Configure aria2 settings for download speed
- Set appropriate timeout values

## 🛠️ Troubleshooting

### Common Issues

#### 1. DRM Decryption Fails
- Ensure Bento4 is properly installed
- Check if mp4decrypt is in PATH
- Verify MPD URLs and keys are correct

#### 2. Download Failures
- Check internet connectivity
- Verify URLs are accessible
- Ensure sufficient disk space
- Check aria2 configuration

#### 3. Database Connection Issues
- Verify MongoDB connection string
- Check network connectivity
- Ensure proper authentication
- Verify database permissions

#### 4. Bot Not Responding
- Check bot token validity
- Verify API credentials
- Check for rate limiting
- Review error logs

### Log Files
- `logs.txt` - Main application logs
- Check console output for real-time errors
- Use `/logs` command to download log files

## 📊 Monitoring

### Health Checks
- Bot responds to `/start` command
- Database connection is active
- FFmpeg and aria2 are working
- Disk space is sufficient

### Performance Metrics
- Download success rate
- Processing time per file
- Memory usage
- Error frequency

## 🔒 Security Considerations

### Best Practices
- Use environment variables for sensitive data
- Regularly update dependencies
- Monitor user access logs
- Implement rate limiting
- Use HTTPS for all external connections

### Access Control
- Admin-only commands are protected
- User authorization is time-based
- Database queries are sanitized
- File uploads are validated

## 🤝 Contributing

### Development Setup
1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

### Code Style
- Follow PEP 8 guidelines
- Use meaningful variable names
- Add comments for complex logic
- Include error handling

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🆘 Support

### Getting Help
- Create an issue on GitHub
- Contact the developer
- Check the documentation
- Review existing issues

### Community
- Join our Telegram group
- Follow updates on GitHub
- Share your experiences
- Contribute to the project

## 🙏 Acknowledgments

- **Pyrogram** - Telegram API library
- **yt-dlp** - Video downloader
- **FFmpeg** - Media processing
- **MongoDB** - Database solution
- **Bento4** - DRM decryption tools

---

**⚠️ Disclaimer**: This bot is for educational purposes only. Users are responsible for complying with applicable laws and terms of service of the platforms they use.

**🔗 Links**:
- [GitHub Repository](https://github.com/vkmalani9/vk-uploader-pro-2)
- [Telegram Bot](https://t.me/your_bot_username)
- [Support Group](https://t.me/your_support_group)

---

*Made with ❤️ by [Vikram Malani](https://github.com/vkmalani9)*