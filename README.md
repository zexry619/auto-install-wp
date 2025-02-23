# WordPress Auto Installer for cPanel

Repository ini berisi dua script Bash untuk mengotomatiskan instalasi WordPress di cPanel menggunakan **wp-cli** dan **uapi**.

## Daftar Isi
- [Deskripsi](#deskripsi)
- [Fitur](#fitur)
- [Persyaratan](#persyaratan)
- [Cara Penggunaan](#cara-penggunaan)
- [Catatan](#catatan)

## Deskripsi
Script ini dibuat untuk memudahkan proses instalasi WordPress melalui cPanel. Tersedia dua versi:
- **Single Domain**: [wordpress_auto.sh](./wordpress_auto.sh)  
  Menginstall WordPress pada satu domain.
- **Multiple Domain**: [wordpress_auto_multi.sh](./wordpress_auto_multi.sh)  
  Menginstall WordPress secara otomatis pada beberapa domain sekaligus.

## Fitur
- Mengambil **DocumentRoot** domain via uapi dan **jq**.
- Membuat database, user database, dan mengatur privileges melalui uapi.
- Mengunduh WordPress core dengan wp-cli dan membuat file konfigurasi secara otomatis.
- Instalasi WordPress lengkap dengan pembuatan admin user (dengan opsi menggunakan kredensial yang sama untuk multiple domain).

## Persyaratan
Pastikan server Anda sudah terinstall:
- **uapi** (cPanel API)
- **jq**
- **wp-cli**
- **openssl**
- **shuf**

Pastikan juga file script disimpan dengan format Unix (LF) untuk menghindari error "command not found" karena karakter CRLF.

## Cara Penggunaan

### Instalasi Single Domain
1. Ubah permission script agar dapat dieksekusi:
   ```bash
   chmod +x wordpress_auto.sh
