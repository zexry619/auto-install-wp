#!/bin/bash
# Script Auto Install WordPress dengan wp-cli dan uapi untuk cPanel (Multiple Domain)

echo "=== Auto Install WordPress ==="
echo ""
read -p "Pilih mode instalasi (s: single, m: multiple) [s/m]: " MODE
MODE=${MODE:-s}

if [ "$MODE" == "s" ]; then
  # --- Instalasi Single Domain ---
  read -p "Masukkan nama domain (misal: next.zekri.id): " DOMAIN
  if [ -z "$DOMAIN" ]; then
    echo "Domain tidak boleh kosong!"
    exit 1
  fi

  read -p "Masukkan admin username (default: admin): " WP_ADMIN_USER
  [ -z "$WP_ADMIN_USER" ] && WP_ADMIN_USER="admin"

  read -p "Masukkan admin password (default: akan dibuat random): " WP_ADMIN_PASSWORD
  if [ -z "$WP_ADMIN_PASSWORD" ]; then
    WP_ADMIN_PASSWORD=$(openssl rand -base64 12)
  fi

  read -p "Masukkan admin email (default: admin@$DOMAIN): " WP_ADMIN_EMAIL
  [ -z "$WP_ADMIN_EMAIL" ] && WP_ADMIN_EMAIL="admin@$DOMAIN"

  CPANELUSER=$(basename "$HOME")
  RANDOM_NUM=$(shuf -i 1000-9999 -n 1)
  DB_NAME="${CPANELUSER}_wp${RANDOM_NUM}"
  DB_USER="${CPANELUSER}_wp${RANDOM_NUM}"
  DB_PASS=$(openssl rand -base64 12)

  echo ""
  echo "Mengambil DocumentRoot untuk domain: $DOMAIN"
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

  echo "Membuat database: $DB_NAME"
  uapi --output=jsonpretty Mysql create_database name="$DB_NAME"

  echo ""
  echo "Membuat user database: $DB_USER"
  uapi --output=jsonpretty Mysql create_user name="$DB_USER" password="$DB_PASS"

  echo ""
  echo "Mengatur privileges untuk user $DB_USER pada database $DB_NAME"
  uapi --output=jsonpretty Mysql set_privileges_on_database user="$DB_USER" database="$DB_NAME" privileges="ALL%20PRIVILEGES"

  sleep 3

  echo ""
  echo "Mengunduh WordPress core..."
  wp core download --path="$DOCUMENTROOT" --locale=id_ID

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

else
  # --- Instalasi Multiple Domain ---
  read -p "Masukkan daftar domain (pisahkan dengan spasi): " DOMAIN_LIST
  if [ -z "$DOMAIN_LIST" ]; then
    echo "Daftar domain tidak boleh kosong!"
    exit 1
  fi

  read -p "Gunakan admin credentials yang sama untuk semua domain? (y/n, default: y): " SAME_CREDS
  SAME_CREDS=${SAME_CREDS:-y}

  if [ "$SAME_CREDS" == "y" ]; then
    read -p "Masukkan admin username (default: admin): " WP_ADMIN_USER
    [ -z "$WP_ADMIN_USER" ] && WP_ADMIN_USER="admin"

    read -p "Masukkan admin password (default: akan dibuat random): " WP_ADMIN_PASSWORD
    if [ -z "$WP_ADMIN_PASSWORD" ]; then
      WP_ADMIN_PASSWORD=$(openssl rand -base64 12)
    fi

    read -p "Masukkan admin email (default: akan disesuaikan per domain): " WP_ADMIN_EMAIL
    # Jika kosong, nantinya akan diset default admin@<domain> tiap domain
  fi

  CPANELUSER=$(basename "$HOME")

  for DOMAIN in $DOMAIN_LIST; do
    echo "========================================"
    echo "Memproses domain: $DOMAIN"
    echo "========================================"

    if [ "$SAME_CREDS" != "y" ]; then
      read -p "Masukkan admin username untuk $DOMAIN (default: admin): " WP_ADMIN_USER
      [ -z "$WP_ADMIN_USER" ] && WP_ADMIN_USER="admin"

      read -p "Masukkan admin password untuk $DOMAIN (default: akan dibuat random): " WP_ADMIN_PASSWORD
      if [ -z "$WP_ADMIN_PASSWORD" ]; then
        WP_ADMIN_PASSWORD=$(openssl rand -base64 12)
      fi

      read -p "Masukkan admin email untuk $DOMAIN (default: admin@$DOMAIN): " WP_ADMIN_EMAIL
      [ -z "$WP_ADMIN_EMAIL" ] && WP_ADMIN_EMAIL="admin@$DOMAIN"
    else
      [ -z "$WP_ADMIN_EMAIL" ] && WP_ADMIN_EMAIL="admin@$DOMAIN"
    fi

    echo ""
    echo "Mengambil DocumentRoot untuk domain: $DOMAIN"
    DOCUMENTROOT=$(uapi --output=json DomainInfo domains_data | jq -r --arg domain "$DOMAIN" '
      .result.data as $data |
      ($data.main_domain | select(.domain == $domain) | .documentroot) //
      ($data.addon_domains[] | select(.domain == $domain) | .documentroot) //
      ($data.sub_domains[] | select(.domain == $domain) | .documentroot)
    ')
    if [ -z "$DOCUMENTROOT" ]; then
      echo "DocumentRoot untuk domain $DOMAIN tidak ditemukan, lanjut ke domain berikutnya."
      continue
    fi
    echo "DocumentRoot ditemukan: $DOCUMENTROOT"

    RANDOM_NUM=$(shuf -i 1000-9999 -n 1)
    DB_NAME="${CPANELUSER}_wp${RANDOM_NUM}"
    DB_USER="${CPANELUSER}_wp${RANDOM_NUM}"
    DB_PASS=$(openssl rand -base64 12)

    echo ""
    echo "Membuat database: $DB_NAME"
    uapi --output=jsonpretty Mysql create_database name="$DB_NAME"

    echo ""
    echo "Membuat user database: $DB_USER"
    uapi --output=jsonpretty Mysql create_user name="$DB_USER" password="$DB_PASS"

    echo ""
    echo "Mengatur privileges untuk user $DB_USER pada database $DB_NAME"
    uapi --output=jsonpretty Mysql set_privileges_on_database user="$DB_USER" database="$DB_NAME" privileges="ALL%20PRIVILEGES"

    sleep 3

    echo ""
    echo "Mengunduh WordPress core..."
    wp core download --path="$DOCUMENTROOT" --locale=id_ID

    cd "$DOCUMENTROOT" || { echo "Gagal masuk ke $DOCUMENTROOT, lanjut ke domain berikutnya."; continue; }

    echo "Membuat file konfigurasi wp-config.php..."
    wp config create --dbname="$DB_NAME" --dbuser="$DB_USER" --dbpass="$DB_PASS" --dbhost=localhost --dbprefix=wp_ --dbcharset=utf8

    echo "Melakukan instalasi WordPress..."
    wp core install --url="$DOMAIN" --title="WordPress $DOMAIN" --admin_user="$WP_ADMIN_USER" --admin_password="$WP_ADMIN_PASSWORD" --admin_email="$WP_ADMIN_EMAIL"

    echo ""
    echo "---------------------------"
    echo "Instalasi untuk $DOMAIN selesai."
    echo "Detail Database:"
    echo "  Nama Database : $DB_NAME"
    echo "  User Database : $DB_USER"
    echo "  Password      : $DB_PASS"
    echo "Detail Admin WordPress:"
    echo "  Username : $WP_ADMIN_USER"
    echo "  Password : $WP_ADMIN_PASSWORD"
    echo "  Email    : $WP_ADMIN_EMAIL"
    echo "---------------------------"
    echo ""

    cd "$HOME" || exit 1
  done
  echo "Semua domain telah diproses."
fi
