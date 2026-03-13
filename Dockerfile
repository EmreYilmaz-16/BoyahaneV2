FROM lucee/lucee:6.0-nginx

# Set working directory
WORKDIR /var/www

# Copy application files
COPY . /var/www/

# Expose ports
EXPOSE 80 8888

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
  CMD curl -f http://localhost/ || exit 1
