FROM lucee/lucee:6.0-nginx

# Set working directory
WORKDIR /var/www

# Install runtime dependencies used by update center
RUN apt-get update \
  && apt-get install -y --no-install-recommends git \
  && rm -rf /var/lib/apt/lists/*

# Copy application files
COPY . /var/www/

# Nginx config override: static file serving + security rules
COPY docker/nginx/default.conf /etc/nginx/conf.d/default.conf

# Fix file permissions so nginx (www-data) can read static assets
RUN find /var/www/assets -type d -exec chmod 755 {} \; && \
    find /var/www/assets -type f -exec chmod 644 {} \;

# Expose ports
EXPOSE 80 8888

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
  CMD curl -f http://localhost/ || exit 1
