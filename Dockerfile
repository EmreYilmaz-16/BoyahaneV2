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

# Tomcat config override: increase maxPostSize to 20MB
COPY docker/tomcat/server.xml /usr/local/tomcat/conf/server.xml

# Entrypoint: fix permissions at runtime (volume mounts override build-time perms)
COPY docker/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# Expose ports
EXPOSE 80 8888

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
  CMD curl -f http://localhost/ || exit 1

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["supervisord", "-c", "/etc/supervisor/supervisord.conf"]
