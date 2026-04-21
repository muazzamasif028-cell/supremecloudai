#!/bin/bash

# Supreme Cloud AI - Domain Connect Script
# Run this ONCE on your server to connect domain

DOMAIN="supremecloudai.com"
SERVER_IP=$(curl -s ifconfig.me)

echo "🚀 Connecting $DOMAIN to Supreme Cloud AI..."

# 1. Install Nginx
sudo apt update && sudo apt install nginx -y

# 2. Create Nginx config
sudo tee /etc/nginx/sites-available/supremecloudai > /dev/null << EOF
server {
    listen 80;
    server_name $DOMAIN www.$DOMAIN;
    
    location / {
        proxy_pass http://localhost:8080;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_cache_bypass \$http_upgrade;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOF

# 3. Enable site
sudo ln -sf /etc/nginx/sites-available/supremecloudai /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default
sudo nginx -t && sudo systemctl reload nginx

# 4. Install SSL
sudo apt install certbot python3-certbot-nginx -y
sudo certbot --nginx -d $DOMAIN -d www.$DOMAIN --non-interactive --agree-tos --email admin@$DOMAIN

# 5. Setup PM2 for Node.js
npm install -g pm2
pm2 start backend/server.js --name supremecloudai
pm2 save
pm2 startup

echo ""
echo "✅ DOMAIN CONNECTED!"
echo "🌐 https://$DOMAIN"
echo "📡 Server IP: $SERVER_IP"
echo ""
echo "📋 Add this DNS record at your domain provider:"
echo "   Type: A"
echo "   Name: @"
echo "   Value: $SERVER_IP"
