#!/usr/bin/env bash
set -e

__get_current_status() {
  __ss="$(bw status --raw | jq .status -r)"
  echo "${__ss}"
}

current_status=$(__get_current_status)

if [[ "${current_status}" == "unauthenticated" ]]; then
  echo "Bitwarden is not logged in"
  echo "Press Y if you wish to use API key for login :: (Default email id based login)"
  read -r -n1 -p "Press any other key to skip : " __is_api_login
  echo ""
  if [[ "${__is_api_login}" == "Y" || "${__is_api_login}" == "y" ]]; then

    if [[ -z "${BW_CLIENTID}" || -z "${BW_CLIENTSECRET}" ]]; then
      read -r -p "Enter Client ID : " -s __bw_client_id
      echo ""
      read -r -p "Enter Client Secret : " -s __bw_client_secret
      echo ""
      read -r -n1 -p "Press y to save client id and client secret in ${HOME}/.secrets" __save_apikeys_in_secrets
      if [[ "${__save_apikeys_in_secrets}" == "Y" || "${__save_apikeys_in_secrets}" == "y" ]]; then
        echo "export BW_CLIENTID=${__bw_client_id}" >>"${HOME}/.secrets"
        echo "export BW_CLIENTSECRET=${__bw_client_secret}" >>"${HOME}/.secrets"
      fi
      BW_CLIENTID="${__bw_client_id}" BW_CLIENTSECRET="${__bw_client_secret}" bw login --apikey
    fi

    bw login --apikey

  else

    bw login

  fi
  current_status=$(__get_current_status)
fi

if [[ "${current_status}" == "locked" ]]; then
  echo ""
  echo "Bitwarden is locked"
  echo ""
  __bw_session_id=$(bw unlock --raw)
  echo ""
  echo "Session id is ${__bw_session_id}"
  echo ""
  echo "export BW_SESSION=${__bw_session_id}"
  echo ""
  read -n1 -r -p "Set session id in ${HOME}/.secrets : " __set_session_id_in_secrets
  echo ""
  if [[ "${__set_session_id_in_secrets}" == "Y" || "${__set_session_id_in_secrets}" == "y" ]]; then
    echo "export BW_SESSION=${__bw_session_id}" >>"${HOME}/.secrets"
  fi
fi

if [ "unlocked" != "$(bw status --raw | jq .status -r)" ]; then
  echo "bitwarden cli is not unlocked"
  exit 0
fi

#############################################################################################################################
#############################################################################################################################

echo ""
echo "Downloading openssh key from bit warden"
echo ""
mkdir -p "${HOME}/.ssh" && chmod 700 "${HOME}/.ssh"
rm -rf /home/arpan/.ssh/arpan_id_rsa
__openssh_key_bw_item=$(bw get item "OpenSSH Key" --raw)

bw get attachment arpan_id_rsa --itemid "$(echo "$__openssh_key_bw_item" | jq .id -r)" --raw >"${HOME}/.ssh/arpan_id_rsa"

chmod 400 "${HOME}/.ssh/arpan_id_rsa"
echo ""
file "${HOME}/.ssh/arpan_id_rsa"
echo ""
echo ""
echo "Open SSH Key Written in ${HOME}/.ssh/arpan_id_rsa"
echo ""

#############################################################################################################################
#############################################################################################################################

echo ""
echo "Downloading gpg key for code signing"
echo ""

mkdir -p "${HOME}/.gnupg" && chmod 700 "${HOME}/.gnupg"

__git_gpg_key=$(git config --get user.signingkey)

echo ""
echo "GPG Key id attached in gitconfig $__git_gpg_key"
echo ""

__bw_git_gpg_item=$(bw get item "$__git_gpg_key")

bw get attachment "private.asc" --itemid "$(echo "$__bw_git_gpg_item" | jq .id -r)" --raw |
  gpg --allow-secret-key-import --import --batch --passphrase "$(echo "$__bw_git_gpg_item" | jq .login.password -r)"

echo ""
echo "Listing private keys"
echo ""
gpg -K
echo ""

#############################################################################################################################
#############################################################################################################################
