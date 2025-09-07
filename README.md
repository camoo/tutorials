# WordPress Local Development Environment with Docker


# Generate a local trusted cert (mkcert)
```bash
sudo apt install -y libnss3-tools # if needed
# Install mkcert (choose one):
# a) from package manager if available
# b) or download from https://github.com/FiloSottile/mkcert/releases and place it in /usr/local/bin

mkcert -install
mkdir -p .certs
mkcert -key-file .certs/wp.localhost-key.pem -cert-file .certs/wp.localhost-cert.pem wp.localhost pma.localhost
```


# Install WordPress now (one-liner)
```bash
docker compose -p wpdemo exec wordpress wp core install \
  --url="$WP_URL" \
  --title="$WP_TITLE" \
  --admin_user="$WP_ADMIN_USER" \
  --admin_password="$WP_ADMIN_PASS" \
  --admin_email="$WP_ADMIN_EMAIL" \
  --path=/var/www/html \
  --allow-root
```

# MailHog SMTP settings for WordPress
Web UI at http://localhost:8025



# Add the following lines to `wp-config.php` to configure WordPress to send emails via Mail

```angular2html
define('WP_MAIL_SMTP_HOST', 'mailhog');
define('WP_MAIL_SMTP_PORT', 1025);

```

# Access WordPress
- WordPress: https://wp.localhost:8443
- phpMyAdmin: https://pma.localhost:8443
- MailHog: http://localhost:8025

# Video Tutorial
[![Watch the video](https://img.youtube.com/vi/your_video_id/hqdefault.jpg)](https://youtu.be/your_video_id)

# Make the mouse pointer easier to find (Linux GNOME)
```bash
gsettings set org.gnome.desktop.interface locate-pointer true
# press and release Ctrl to show a ripple around the cursor
```

# Access apache logs
```bash
docker compose -p wpdemo logs -f apache

```