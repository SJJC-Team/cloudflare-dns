# domain

set -e

rm -f "$CERTI_NGINX_DIR/$domain.conf"
rm -rf "$CERTI_NGINX_DIR/certs/$domain.ssl-certs"