#!/bin/bash

certbot="/usr/bin/certbot"
echo "${certbot}" >/dev/null;
acme="/root/.acme.sh/acme.sh"

code=0

domain=$(cat /etc/hostname)
cloudflare="yes"
cloudflare_api="/root/.config/certbot/cloudflare.ini"
cloudflare_settings="/root/.config/certbot/cloudflare_settings.cfg"
cloudflare_zone="9d4f444d92f6b3e8a4c30e60a2f13db6"
cloudflare_default_ssl="strict"
cloudflare_renew_ssl="flexible"
cloudflare_email="thakyz@outlook.com"

CF_Token=$(grep dns_cloudflare_api_token "${cloudflare_api}" | sed 's/dns_cloudflare_api_token = //')
export CF_Token;
export CF_Account_ID="${cloudflare_email}"
export CF_Zone_ID="${cloudflare_zone}"

function check_ssl_expire() {
  local cloudflareKey=""
  local _strB=""
  cloudflareKey=$(grep dns_cloudflare_api_key "${cloudflare_settings}" | sed 's/dns_cloudflare_api_key = //')
  header="${cloudflareKey}"
  _strB="curl -s -X GET \"https://api.cloudflare.com/client/v4/zones/${cloudflare_zone}/ssl/certificate_packs\""
  _strB="${_strB} -H \"Content-Type: application/json\""
  _strB="${_strB} -H \"X-Auth-Email: ${cloudflare_email}\""
  _strB="${_strB} -H \"X-Auth-Key: $header"
  data=$_strB
  expires_on=$(echo "${data}" | jq -r ".result[] | select(.hosts[] == \"${domain}\") | .certificates[] | select(.hosts[] == \"${domain}\") | .expires_on")
  expires_unix=$(date -d "${expires_on}" +"%s")
  date_now=$(date +"%s")
  soon_to_be=$(echo "(${expires_unix} - ${date_now}) / 604800" | bc)
  if [ "${soon_to_be}" == "1" ] || [ "${soon_to_be}" == "0" ]; then
    return 1;
  fi
  return 0;
}

#if [ $(check_ssl_expire) == "0" ]; then
#  echo -e "SSL certificate is not expired.\n"
#  exit 0
#fi

#$(which service) nginx stop

# shellcheck disable=SC2317
function test_data() {
  local data="${1}";
  local success;
  success="$(echo "${data}" | jq -r '.success')"
  if [ "${success}" == "true" ]; then
    return 1;
  else
    return 2;
  fi
}

# shellcheck disable=SC2317
function switch_ssl_mode() {
  local mode=${1:='true'}
  local _strB=""
  local cloudflareKey=""
  local success=0
    cloudflareKey=$(grep dns_cloudflare_api_key "${cloudflare_settings}" | sed 's/dns_cloudflare_api_key = //')
  header="${cloudflareKey}"
  _strB="curl -s -X PATCH 'https://api.cloudflare.com/client/v4/zones/${cloudflare_zone}/settings/ssl'"
  _strB="${_strB} -H 'X-Auth-Email: ${cloudflare_email}'"
  _strB="${_strB} -H 'X-Auth-Key: ${header}'"
  _strB="${_strB} -H 'Content-Type: application/json'"
  if [ "${mode}" == 'true' ]; then
    _strB="${_strB} --data '{\"value\":\"${cloudflare_default_ssl}\"}'"
    data="${_strB}"
    if [[ "$(echo "${data}" | jq -r '.success')" == "true" ]]; then
      success=1
    else
      success=0
    fi
  else
    _strB="${_strB} --data '{\"value\":\"${cloudflare_renew_ssl}\"}'"
    data="${_strB}"
    if [[ "$(echo "${data}" | jq -r '.success')" == "true" ]]; then
      success=1
    else
      success=0
    fi
  fi
  echo -e "\n" >&2
  echo "${success}"
}

function kill_nginx() {
  local _code=0;

  $(which service) nginx stop;
  _code=$?;

  if [ "${code}" != "0" ]; then
    mapfile -t PIDS < <(pgrep -f "nginx")

    if [ ${#PIDS[@]} -ne 0 ]; then
      kill -9 "${PIDS[@]}"
    fi
  fi

  echo $_code
}

#kill_nginx

#if [ $(switch_ssl_mode "false") == "0" ]; then
#  echo -e "Failed to switch ssl mode\n"
#  exit 1
#fi

function run_for_domain() {
  local domains="${1}"
  local data=""
  local _code=0
  # echo ${1}
  echo "Running certonly on domain: ${domains}"

  # cmd="${certbot} certonly --dns-cloudflare --dns-cloudflare-credentials=\"${cloudflare_api}\" -d ${domain} -q"
  # cmd="${certbot} certonly --dns-cloudflare --manual --preferred-challenges dns -d ${domain} -q"
  cmd="${acme} --debug 2 --ocsp-must-staple --keylength 4096 --issue --dns dns_cf ${domains} --server letsencrypt --key-file /etc/letsencrypt/live/example.com/privkey.pem --fullchain-file /etc/letsencrypt/live/example.com/fullchain.pem"
  data="$(${cmd})"
  _code=$?

  if [[ $data == *"Skip, Next renewal time is"* ]]; then
    return 0
  fi

  echo $_code
}

function run_renew() {
  local _code=0
  if [ $cloudflare == "yes" ]; then
    # domains="$(certbot certificates | grep -zoP 'Domains: .*\n.*\(VALID' | sed 's/[ \t]*Domains: //g' | sed 's/[[:space:]]*Expiry Date:[[:space:]][0-9]\+-[0-9]\+-[0-9]\+[[:space:]][0-9]\+:[0-9]\+:[0-9]\++[0-9]\+:[0-9]\+[[:space:]](VALID//g' | tr -d '\0')"
    domains=("example.com" "'*.example.com'")
    attached=""
    expired="$(check_ssl_expire)"
    if [ "${expired}" == "0" ]; then
      return 1;
    fi
    for domain in "${domains[@]}"; do
      echo "\$domain = ${domain}" >&2
      attached="${attached} -d ${domain}"
    done
    echo "\$attached = ${attached}" >&2
    _code="$(run_for_domain "${attached}")"
    if [[ $_code -ne 0 ]]; then
      echo "Had an error" >&2
    else
      echo "Completeded successfully" >&2
    fi
  fi
  echo $_code
}

code=$(run_renew)

#if [ $cloudflare != "yes" ]; then
#  echo "Running renew as standalone"
#  cmd="${certbot} renew --standalone"
#
#  eval "${cmd}"
#  code=$?
#fi

#if [ $(switch_ssl_mode "true") == "0" ]; then
#  echo -e "Failed to switch ssl mode\n"
#  exit 1
#fi

if [[ $code -eq 0 ]]; then
  echo "Completeded successfully"
else
  echo "Had an error"
fi

kill_nginx

$(which service) nginx start

echo "Exit Code: ${code}"
# shellcheck disable=SC2086
exit $code