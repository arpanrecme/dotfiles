#!/usr/bin/env bash
set -e

__get_current_status() {
  __ss="$(bw status --raw | jq .status -r)"
  echo "${__ss}"
}

current_status=$(__get_current_status)

if [ "${current_status}" == "unauthenticated" ]; then
  echo "Bitwarden is not logged in"
  echo "Press Y if you wish to use API key for login :: (Default email id based login)"
  read -r -n1 -p "Press any other key to skip : " __is_api_login
  echo ""
  if [ "${__is_api_login}" == "Y" ] || [ "${__is_api_login}" == "y" ]; then

    if [ -z "${BW_CLIENTID}" ] || [ -z "${BW_CLIENTSECRET}" ]; then
      read -r -p "Enter Client ID : " -s __bw_client_id
      echo ""
      read -r -p "Enter Client Secret : " -s __bw_client_secret
      echo ""
      if [ -z "${__bw_client_id}" ] || [ -z "${__bw_client_secret}" ]; then
        echo ""
        echo "Error!!!!!!!!!!!!!!!! Enter Valid Keys"
        echo ""
        exit 1
      fi
      read -r -n1 -p "Press Y/y to save client id and client secret in ${HOME}/.secrets :: " __save_apikeys_in_secrets
      if [ "${__save_apikeys_in_secrets}" == "Y" ] || [ "${__save_apikeys_in_secrets}" == "y" ]; then
        sed -i '/export BW_CLIENTID=*/d' "${HOME}/.secrets"
        sed -i '/export BW_CLIENTSECRET=*/d' "${HOME}/.secrets"
        echo "export BW_CLIENTID=${__bw_client_id}" >>"${HOME}/.secrets"
        echo "export BW_CLIENTSECRET=${__bw_client_secret}" >>"${HOME}/.secrets"
      fi
      echo ""
      echo "Logging in to bitwarden cli, Please Wait!!!!!!!!!!!!"
      echo ""
      BW_CLIENTID="${__bw_client_id}" BW_CLIENTSECRET="${__bw_client_secret}" bw login --apikey

    else
      echo ""
      echo "Client ID and Client Secret found in environment"
      echo "Please Wait!!!!!!!!!!!!"
      echo ""
      bw login --apikey
    fi

  else
    bw login
  fi
  current_status=$(__get_current_status)
fi

if [ "${current_status}" == "locked" ]; then
  echo ""
  echo "Bitwarden is locked"
  echo "Current user "" $(bw status --raw | jq .userEmail)"
  read -r -p "Unlocking Bitwarden, Enter you credential : " -s __bw_master_password
  if [ -z "${__bw_master_password}" ]; then
    echo ""
    echo "Error!!!!!!!!!!!!!!!! Enter Valid Credential"
    echo ""
    exit 1
  fi
  echo ""
  __bw_session_id=$(bw unlock "${__bw_master_password}" --raw)
  echo ""
  if [ -z "${__bw_session_id}" ]; then
    echo ""
    echo "Error!!!!!!!!!!!!!!!! Unable to unlock"
    echo ""
    exit 1
  fi
  export BW_SESSION="${__bw_session_id}"
  echo "Session id is ${__bw_session_id}"
  echo ""
  echo "export BW_SESSION=${__bw_session_id}"
  echo ""
  read -n1 -r -p "Set session id in ${HOME}/.secrets : " __set_session_id_in_secrets
  echo ""
  if [ "${__set_session_id_in_secrets}" == "Y" ] || [ "${__set_session_id_in_secrets}" == "y" ]; then
    sed -i '/export BW_SESSION=*/d' "${HOME}/.secrets"
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
echo "Will download any attachment with entry name containing \"OpenSSH key\""
read -r -n1 -p "Download openssh key from bitwarden : [y/n] " __is_download_openssh_key
echo ""
if [ "${__is_download_openssh_key}" == "Y" ] || [ "${__is_download_openssh_key}" == "y" ]; then

  bw sync

  __ssh_key_directory="${HOME}/.ssh"

  for item in $(bw list items --search 'OpenSSH key' --raw | jq -r -c '.[] | @base64'); do
    item=$(echo "${item}" | base64 --decode)
    __item_id=$(echo "${item}" | jq -r .id)
    for attachment in $(echo "${item}" | jq -r -c '.attachments' | jq -r -c '.[] | @base64 '); do
      attachment=$(echo "${attachment}" | base64 --decode)
      filename=$(echo "${attachment}" | jq -r .fileName)
      attachment_id=$(echo "${attachment}" | jq -r .id)
      __expected_file_save_path=${__ssh_key_directory}/${filename}
      echo ""
      echo "Downloading \"${filename}\" from \"$(echo "${item}" | jq -r .name)\" to \"${__expected_file_save_path}\""
      echo ""
      if [ -f "${__expected_file_save_path}" ]; then
        echo ""
        echo "File already exists ${__expected_file_save_path}"
        read -r -n1 -p "press y to overwrite, or any other key to skip : " __overwrite_keyfile
        echo ""
        if [ "${__overwrite_keyfile}" == "y" ] || [ "${__overwrite_keyfile}" == "Y" ]; then
          bw get attachment --itemid "${__item_id}" "${attachment_id}" --raw \
            >"${__expected_file_save_path}"
        else
          __expected_file_save_path=${__ssh_key_directory}/${filename}_$(date +%s)
          echo ""
          echo "Save file to ${__expected_file_save_path}"
          echo ""
          bw get attachment --itemid "${__item_id}" "${attachment_id}" --raw \
            >"${__expected_file_save_path}"
        fi
      else
        bw get attachment --itemid "${__item_id}" "${attachment_id}" --raw >"${__expected_file_save_path}"
      fi

    done
  done

fi

#############################################################################################################################
#############################################################################################################################
echo ""
echo "Will download attachment with name \"private.asc\" with entry name containing \"GPG Certificate\""
echo "Password fiend should contain the GPG certificate password"
read -r -n1 -p "Download GPG Certificate from bitwarden : [y/n] " __is_download_gpg_cert
echo ""
if [ "${__is_download_gpg_cert}" == "Y" ] || [ "${__is_download_gpg_cert}" == "y" ]; then

  bw sync

  for item in $(bw list items --search 'GPG Certificate' --raw | jq -r -c '.[] | @base64'); do
    item=$(echo "${item}" | base64 --decode)
    __item_id=$(echo "${item}" | jq -r .id)
    for attachment in $(echo "${item}" | jq -r -c '.attachments' | jq -r -c '.[] | @base64 '); do
      attachment=$(echo "${attachment}" | base64 --decode)
      attachment_id=$(echo "${attachment}" | jq -r .id)
      __raw_file=$(bw get attachment --itemid "${__item_id}" "${attachment_id}" --raw)
      if [[ "$(echo "${__raw_file}" | head -n 1)" =~ "BEGIN PGP PRIVATE KEY BLOCK" ]]; then
        echo ""
        bw get attachment --itemid "${__item_id}" "${attachment_id}" --raw |
          gpg --allow-secret-key-import --import --batch --passphrase \
            "$(echo "${item}" | jq .login.password -r)"
      fi

    done

  done

fi

#############################################################################################################################
#############################################################################################################################
