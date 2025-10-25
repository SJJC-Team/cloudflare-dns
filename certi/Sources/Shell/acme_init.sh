# email eab_kid eab_hmac acme_dir

set -e

r='\033[31m'
g='\033[32m'
b='\033[34m'
n='\033[0m'

acme="$acme_dir/acme.sh"

export LE_WORKING_DIR="$acme_dir"
curl https://get.acme.sh | sh -s email=$email
$acme --upgrade --auto-upgrade
$acme --set-default-ca --server google
$acme --register-account --server google --eab-kid $eab_kid  --eab-hmac-key $eab_hmac