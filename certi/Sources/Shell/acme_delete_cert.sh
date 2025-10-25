# domain wildcard acme_dir

set -e

acme="$acme_dir/acme.sh"

if ! $acme --remove -d $domain ${wildcard:+-d *.$domain}; then
    exit 1
fi

rm -rf $CERTI_NGINX_DIR/certs/$domain.ssl-certs

rm -f /etc/nginx_sites/$domain.conf