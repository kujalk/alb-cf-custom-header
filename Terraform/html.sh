#!/bin/bash
# Update the system
yum update -y

# Install Apache HTTP Server (httpd)
yum install -y httpd

# Start and enable httpd service
systemctl start httpd
systemctl enable httpd

# Create the HTML page
echo "<html><body><h1>Hello, World I am served from AWS CloudFront!</h1></body></html>" > /var/www/html/status.html

# Set the permissions for the HTML page
chown apache:apache /var/www/html/status.html
chmod 644 /var/www/html/status.html

# Restart httpd service
systemctl restart httpd
