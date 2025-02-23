#!/bin/bash
# Script Auto Install WordPress dengan wp-cli dan uapi untuk cPanel

# Tampilkan header
echo "=== Auto Install WordPress ==="

# Input nama domain
read -p "Masukkan nama domain (misal: next.zekri.id): " DOMAIN
if [ -z "$DOMAIN" ]; then
  echo "Domain tidak boleh kosong!"
  exit 1
fi

# Input admin username, password, dan email (opsional)
read -p "Masukkan admin username (default: admin): " WP_ADMIN_USER
if [ -z "$WP_ADMIN_USER" ]; then
  WP_ADMIN_USER="admin"
fi

read -p "Masukkan admin password (default: akan dibuat random): " WP_ADMIN_PASSWORD
if [ -z "$WP_ADMIN_PASSWORD" ]; then
  WP_ADMIN_PASSWORD=$(openssl rand -base64 12)
fi

read -p "Masukkan admin email (default: admin@$DOMAIN): " WP_ADMIN_EMAIL
if [ -z "$WP_ADMIN_EMAIL" ]; then
  WP_ADMIN_EMAIL="admin@$DOMAIN"
fi

# Dapatkan username cPanel dari direktori home
CPANELUSER=$(basename "$HOME")

# Generate angka random 3/4 digit
RANDOM_NUM=$(shuf -i 1000-9999 -n 1)

# Buat nama database dan username database
DB_NAME="${CPANELUSER}_wp${RANDOM_NUM}"
DB_USER="${CPANELUSER}_wp${RANDOM_NUM}"

# Generate password random untuk database user
DB_PASS=$(openssl rand -base64 12)

echo ""
echo "Mengambil DocumentRoot untuk domain: $DOMAIN"
# Dapatkan DocumentRoot menggunakan uapi dan jq
DOCUMENTROOT=$(uapi --output=json DomainInfo domains_data | jq -r --arg domain "$DOMAIN" '
  .result.data as $data |
  ($data.main_domain | select(.domain == $domain) | .documentroot) //
  ($data.addon_domains[] | select(.domain == $domain) | .documentroot) //
  ($data.sub_domains[] | select(.domain == $domain) | .documentroot)
')

if [ -z "$DOCUMENTROOT" ]; then
  echo "DocumentRoot untuk domain $DOMAIN tidak ditemukan."
  exit 1
fi

echo "DocumentRoot ditemukan: $DOCUMENTROOT"
echo ""

# Membuat database menggunakan uapi
echo "Membuat database: $DB_NAME"
uapi --output=jsonpretty Mysql create_database name="$DB_NAME"

echo ""
echo "Membuat user database: $DB_USER"
uapi --output=jsonpretty Mysql create_user name="$DB_USER" password="$DB_PASS"

echo ""
echo "Mengatur privileges untuk user $DB_USER pada database $DB_NAME"
uapi --output=jsonpretty Mysql set_privileges_on_database user="$DB_USER" database="$DB_NAME" privileges="ALL%20PRIVILEGES"

# Tambahkan jeda agar perubahan database terproses
sleep 3

echo ""
echo "Mengunduh WordPress core..."
wp core download --path="$DOCUMENTROOT" --locale=id_ID

# Pindah ke directory DocumentRoot
cd "$DOCUMENTROOT" || { echo "Gagal masuk ke $DOCUMENTROOT"; exit 1; }

echo "Membuat file konfigurasi wp-config.php..."
wp config create --dbname="$DB_NAME" --dbuser="$DB_USER" --dbpass="$DB_PASS" --dbhost=localhost --dbprefix=wp_ --dbcharset=utf8

echo "Melakukan instalasi WordPress..."
wp core install --url="$DOMAIN" --title="WordPress $DOMAIN" --admin_user="$WP_ADMIN_USER" --admin_password="$WP_ADMIN_PASSWORD" --admin_email="$WP_ADMIN_EMAIL"

echo ""
echo "Instalasi WordPress selesai."
echo "---------------------------"
echo "Detail Database:"
echo "  Nama Database : $DB_NAME"
echo "  User Database : $DB_USER"
echo "  Password      : $DB_PASS"
echo ""
echo "Detail Admin WordPress:"
echo "  Username : $WP_ADMIN_USER"
echo "  Password : $WP_ADMIN_PASSWORD"
echo "  Email    : $WP_ADMIN_EMAIL"
echo "---------------------------"
