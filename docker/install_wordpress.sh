#!/usr/bin/env sh

set -e

# Checking MYSQL is ready to be used.
mysql_ready="nc -z ${WORDPRESS_DB_HOST} 3306"

if ! $mysql_ready
then
    echo 'Waiting for MySQL.'
    while ! $mysql_ready
    do
        echo '.'
        sleep 1
    done
    echo
fi

# Check if WP is installed
if wp core is-installed
then
    echo "WordPress is already installed, exiting."
    exit
fi

# Downloading and installing WP
wp core download --force

[ -f wp-config.php ] || wp config create \
    --dbhost="$WORDPRESS_DB_HOST" \
    --dbname="$WORDPRESS_DB_NAME" \
    --dbuser="$WORDPRESS_DB_USER" \
    --dbpass="$WORDPRESS_DB_PASSWORD" \
    --dbprefix="$WORDPRESS_DB_PREFIX"

wp core install \
    --url="$WORDPRESS_URL" \
    --title="$WORDPRESS_TITLE" \
    --admin_user="$WORDPRESS_ADMIN_USER" \
    --admin_password="$WORDPRESS_ADMIN_PASSWORD" \
    --admin_email="$WORDPRESS_ADMIN_EMAIL" \
    --skip-email

# Migrate DB if needed
if [ -z "$MIGRATE_DB_FROM" ]
then
    echo "No DB dump specified in the .env file (MIGRATE_DB_FROM). Skipping data migration."
else
    if [ -f "$MIGRATE_DB_FROM" ]
    then
        wp db import $MIGRATE_DB_FROM
    else
        echo "File $MIGRATE_DB_FROM not found. Skipping data migration."
    fi
fi

# Manage required plugins
wp plugin delete akismet hello

wp plugin install --activate --force \
    advanced-custom-fields \
    custom-post-type-ui \
    wordpress-seo \

# Theme settings
wp theme activate $THEME_NAME
wp theme delete twentytwenty twentytwentyone twentytwentytwo twentytwentythree

wp option update siteurl "$WORDPRESS_URL"
wp option update home "http:${WORDPRESS_HOME}"
wp option update blogname "$WORDPRESS_TITLE"
wp option update blogdescription "$WORDPRESS_DESCRIPTION"
wp rewrite structure "$WORDPRESS_PERMALINK_STRUCTURE"
wp rewrite flush

echo "Install done. You can now log into WordPress at: $WORDPRESS_URL/wp-admin ($WORDPRESS_ADMIN_USER/$WORDPRESS_ADMIN_PASSWORD)"

