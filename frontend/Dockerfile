# Use base nginx image from Docker Hub
FROM nginx

# Copy static web content
COPY html /usr/share/nginx/html

#Copy nginx config 
COPY nginx/default.conf /etc/nginx/conf.d/default.conf
