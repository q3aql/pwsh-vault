#!/bin/bash

###############################################################
# pwsh-vault-dl - Password Manager written with Bash (Dialog) #
# Author: q3aql                                               #
# Contact: q3aql@duck.com                                     #
# License: GPL v2.0                                           #
# Last-Change: 17-07-20222                                    #
# #############################################################
VERSION="0.2"

# Variables
pwsh_vault="${HOME}/.pwsh-vault"
pwsh_vault_masterkey="${pwsh_vault}/masterkey"
pwsh_vault_cache_logins="${HOME}/.cache/pwsh_vault_cache_logins"
pwsh_vault_cache_logins_otp="${HOME}/.cache/pwsh_vault_cache_logins_otp"
pwsh_vault_cache_notes="${HOME}/.cache/pwsh_vault_cache_notes"
pwsh_vault_cache_bcard="${HOME}/.cache/pwsh_vault_cache_bcard"
pwsh_vault_cache_temp="${HOME}/.cache/pwsh_vault_cache_temp"
file_code_sec="${HOME}/.cache/pwsh-vault-seq"
pwsh_vault_password_copy="${HOME}/pwsh-vault-pass-copy.txt"
pwsh_vault_clipboard_copy="${HOME}/pwsh-vault-copy.txt"
show_key_encrypted=0
 
function generate_codes() {
  if [ "${1}" == "password" ] ; then
    chars="abcdefghijklmnopqrstywxz1234567890ABCDEFHIJKLMNOPQRSTYWXZ"
  else
    chars="abcdefghijklmnopqrstywxz1234567890ABCDEFHIJKLMNOPQRSTYWXZ@/"
  fi
  long_code="${1}"
  for i in {1} ; do
    echo -n "${chars:RANDOM%${#chars}:1}"
  done
}

function generate_spaces() {
  num_spaces=${1}
  count_spaces=1
  while [ ${count_spaces} -le ${num_spaces} ] ; do
    echo -n " "
    count_spaces=$(expr ${count_spaces} + 1)
  done
}

function removeSpaces() {
  wordToConvert=${1}
  sedtmpfile="${file_code_sec}"
  echo "${wordToConvert}" > ${sedtmpfile}
  # Remove spaces
  sed -i 's/ /_/g' "${sedtmpfile}" &> /dev/null
  # Show file without spaces
  wordToConvert=$(cat ${sedtmpfile})
  echo ${wordToConvert}
}

function removeSpacesURL() {
  wordToConvert=${1}
  sedtmpfile="${file_code_sec}"
  echo "${wordToConvert}" > ${sedtmpfile}
  # Remove spaces
  sed -i 's/ /%/g' "${sedtmpfile}" &> /dev/null
  # Show file without spaces
  wordToConvert=$(cat ${sedtmpfile})
  echo ${wordToConvert}
}

function spaceForDot() {
  wordToConvert=${1}
  sedtmpfile="${file_code_sec}"
  echo "${wordToConvert}" > ${sedtmpfile}
  # Remove spaces
  sed -i 's/ /??/g' "${sedtmpfile}" &> /dev/null
  # Show file without spaces
  wordToConvert=$(cat ${sedtmpfile})
  echo ${wordToConvert}
}

function restoreSpaces() {
  wordToConvert=${1}
  sedtmpfile="${file_code_sec}"
  echo "${wordToConvert}" > ${sedtmpfile}
  # Remove spaces
  sed -i 's/_/ /g' "${sedtmpfile}" &> /dev/null
  # Show file without spaces
  wordToConvert=$(cat ${sedtmpfile})
  echo ${wordToConvert}
}

function vault_key_encrypt() {
  raw_pass="${1}"
  char_key_raw=$(echo ${raw_pass} | wc -m)
  char_key=$(expr ${char_key_raw} - 1)
  total_char=0
  rm -rf ${file_code_sec}
  while [ ${total_char} -le ${char_key} ] ; do
    num_gen=$(echo -n ${RANDOM} | cut -c1)
    echo -n ${num_gen} >> ${file_code_sec}
    total_char=$(expr ${total_char} + 1)
  done
  char_seq_raw=$(cat ${file_code_sec} 2> /dev/null | wc -m)
  caracteres_seq=$(expr ${char_seq_raw} - 1)
  total_char=1
  key_encripted=""
  while [ ${total_char} -le ${char_key} ] ; do
    num_seq_read=$(cat ${file_code_sec} 2> /dev/null | cut -c${total_char})
    caracter=$(echo ${raw_pass} | cut -c${total_char})
    repeat_seq=0
    while [ ${repeat_seq} -lt ${num_seq_read} ] ; do
      code_gen=$(generate_codes)
      key_encripted="${key_encripted}${code_gen}"
      repeat_seq=$(expr ${repeat_seq} + 1)
    done
    key_encripted="${key_encripted}${caracter}"
    total_char=$(expr ${total_char} + 1)
  done
  code_gen=$(generate_codes)
  key_encripted="${key_encripted}${code_gen}"
  list_seq_codes=$(cat ${file_code_sec})
  rm -rf ${file_code_sec}
  echo "${key_encripted},${list_seq_codes}"
}

function vault_key_decrypt() {
  raw_pass_encrypted=$(echo ${1} | cut -d "," -f 1)
  total_char=1
  codes_seq=$(echo ${1} | cut -d "," -f 2)
  num_codes_seq=$(echo ${codes_seq} | wc -m)
  key_decrypted=""
  total_char=1
  pos_codes_key=0
  while [ ${total_char} -lt ${num_codes_seq} ] ; do
    pos_codes=$(echo ${codes_seq} | cut -c${total_char})
    pos_codes_key=$(expr ${pos_codes_key} + ${pos_codes} + 1)
    pos_pass=$(expr ${raw_pass_encrypted} | cut -c${pos_codes_key})
    key_decrypted="${key_decrypted}${pos_pass}"
    total_char=$(expr ${total_char} + 1)
  done
  echo ${key_decrypted}
}

function generate_password() {
  if [ -z "${1}" ] ; then
    default_long_password=20
  else
    expr ${1} + 1 &> /dev/null
    num_error=$?
    if [ ${num_error} -ne 0 ] ; then
      size_pass=20
    else
      size_pass="${1}"
    fi
    # Create password
    if [ ${size_pass} -lt 8 ] ; then
      default_long_password=10
    else
      default_long_password=${size_pass}
    fi
  fi
  count_char_password=1
  current_password=""
  echo ""
  echo "# Generating Random Password"
  while [ ${count_char_password} -le ${default_long_password} ] ; do
    current_char=$(generate_codes "password")
    current_password="${current_password}${current_char}"
    count_char_password=$(expr ${count_char_password} + 1)
  done
  echo ""
  echo "# PASSWORD: ${current_password}"
  echo ""
  if [ "${2}" != "param" ] ; then
    echo -n "# Press enter key to continue " ; read enter_continue
  fi
}

function gen_password_dl() {
  if [ -z "${1}" ] ; then
    default_long_password=20
  else
    expr ${1} + 1 &> /dev/null
    num_error=$?
    if [ ${num_error} -ne 0 ] ; then
      size_pass=20
    else
      size_pass="${1}"
    fi
    # Create password
    if [ ${size_pass} -lt 8 ] ; then
      default_long_password=10
    else
      default_long_password=${size_pass}
    fi
  fi
  count_char_password=1
  current_password=""
  while [ ${count_char_password} -le ${default_long_password} ] ; do
    current_char=$(generate_codes "password")
    current_password="${current_password}${current_char}"
    count_char_password=$(expr ${count_char_password} + 1)
  done
  echo "${current_password}"
}

function generate_password_menu() {
  echo > /dev/null | dialog --title "# pwsh-vault-dl ${VERSION} $(generate_spaces 20)" \
  --progressbox "# Loading Password Generator \\" 0 0
  size_password=$(dialog --stdout --title "# pwsh-vault-dl ${VERSION} $(generate_spaces 20)" --inputbox "# Set the password size (Default: 20):" 0 0)
  if [ -z "${size_password}" ] ; then
    size_password=20
  fi
  gen_password_dl "${size_password}" > ${pwsh_vault_password_copy} | dialog --title "# pwsh-vault-dl ${VERSION} $(generate_spaces 20)" --progressbox "# Generating Random Password" 0 0
  password_show=$(cat ${pwsh_vault_password_copy})
  dialog --title "# pwsh-vault-dl ${VERSION} $(generate_spaces 40)" --msgbox "# PASSWORD: ${password_show}\n\nPassword has been copied to ${pwsh_vault_password_copy}" 0 0
}

function init_masterkey() {
  if [ -f ${pwsh_vault_masterkey} ] ; then
    read_masterkey_vault=$(dialog --stdout --title "# pwsh-vault-dl ${VERSION} $(generate_spaces 20)" --passwordbox "# Enter MasterKey Vault:" 0 0)
    echo > /dev/null | dialog --title "# pwsh-vault-dl ${VERSION} $(generate_spaces 20)" \
  --progressbox "# Checking The Entered Masterkey \\" 0 0
    read_masterkey=$(cat ${pwsh_vault_masterkey} | cut -d ";" -f 2)
    decrypt_masterkey=$(vault_key_decrypt "${read_masterkey}")
    if [ "${decrypt_masterkey}" == "${read_masterkey_vault}" ] ; then
      echo > /dev/null
    else
      dialog --title "# pwsh-vault-dl ${VERSION} $(generate_spaces 20)" --msgbox "# Wrong MasterKey" 0 0
      exit
    fi
  else
    masterkey_input=$(dialog --stdout --title "# A masterkey has not yet been defined" --passwordbox "# Enter New MasterKey:" 0 0)
    masterkey_reinput=$(dialog --stdout --title "# A masterkey has not yet been defined" --passwordbox "# Re-Enter New MasterKey:" 0 0)
    echo > /dev/null | dialog --title "# pwsh-vault-dl ${VERSION} $(generate_spaces 20)" \
  --progressbox "# Checking The Entered Masterkey \\" 0 0
    if [ "${masterkey_input}" == "${masterkey_reinput}" ] ; then
      echo ""
      masterkey_name=$(vault_key_encrypt "Masterkey")
      masterkey_gen=$(vault_key_encrypt "${masterkey_input}")
      echo "${masterkey_name};${masterkey_gen}" > ${pwsh_vault_masterkey}
      dialog --title "# pwsh-vault-dl ${VERSION} $(generate_spaces 20)" --msgbox "# New MasterKey defined correctly" 0 0
    else
      dialog --title "# pwsh-vault-dl ${VERSION} $(generate_spaces 20)" --msgbox "# Both passwords do not match" 0 0
      exit
    fi
  fi
}

function create_login_vault_entry() {
  echo > /dev/null | dialog --title "# pwsh-vault-dl ${VERSION} $(generate_spaces 20)" \
  --progressbox "# Loading Section for Create Entry \\" 0 0
  name_login_entry=0
  masterkey_load=$(cat ${pwsh_vault_masterkey})
  while [ ${name_login_entry} -eq 0 ] ; do
    name_entry=$(dialog --stdout --title "# pwsh-vault-dl ${VERSION} $(generate_spaces 20)" --inputbox "# Enter Name for Login Entry:" 0 0)
    if [ ! -z "${name_entry}" ] ; then
      name_entry=$(removeSpaces "${name_entry}")
      if [ -d "${pwsh_vault}/logins/${name_entry}" ] ; then
        dialog --title "# pwsh-vault-dl ${VERSION} $(generate_spaces 20)" \
        --msgbox "# Vault logins/${name_entry} already exists\n# You can remove or edit it." 0 0
        pwsh_vault_main
      fi
      mkdir -p "${pwsh_vault}/logins/${name_entry}"
      name_login_entry=1
    fi
  done
  username_entry=0
  while [ ${username_entry} -eq 0 ] ; do
    name_username=$(dialog --stdout --title "# pwsh-vault-dl ${VERSION} $(generate_spaces 20)" --inputbox "# Enter Username:" 0 0)
    if [ ! -z "${name_username}" ] ; then
      name_username=$(spaceForDot "${name_username}")
      name_username=$(vault_key_encrypt "${name_username}")
      username_text=$(vault_key_encrypt "Username")
      echo "${masterkey_load}" > "${pwsh_vault}/logins/${name_entry}/login"
      echo "${username_text};${name_username}" >> "${pwsh_vault}/logins/${name_entry}/login"
      username_entry=1
    fi
  done
  password_entry=0
  while [ ${password_entry} -eq 0 ] ; do
    name_password=$(dialog --stdout --title "# pwsh-vault-dl ${VERSION} $(generate_spaces 20)" --inputbox "# Enter Password:" 0 0)
    if [ ! -z "${name_password}" ] ; then
      name_password=$(spaceForDot "${name_password}")
      name_password=$(vault_key_encrypt "${name_password}")
      password_text=$(vault_key_encrypt "Password")
      echo "${masterkey_load}" > "${pwsh_vault}/logins/${name_entry}/password"
      echo "${password_text};${name_password}" >> "${pwsh_vault}/logins/${name_entry}/password"
      password_entry=1
    fi
  done
  url_entry=0
  while [ ${url_entry} -eq 0 ] ; do
    name_url=$(dialog --stdout --title "# pwsh-vault-dl ${VERSION} $(generate_spaces 40)" --inputbox "# Enter URL:" 0 0)
    if [ ! -z "${name_url}" ] ; then
      name_url=$(removeSpacesURL "${name_url}")
      name_url=$(vault_key_encrypt "${name_url}")
      url_text=$(vault_key_encrypt "URL")
      echo "${masterkey_load}" > "${pwsh_vault}/logins/${name_entry}/url"
      echo "${url_text};${name_url}" >> "${pwsh_vault}/logins/${name_entry}/url"
      url_entry=1
    fi
  done
  otp_entry=0
  while [ ${otp_entry} -eq 0 ] ; do
    name_otp=$(dialog --stdout --title "# pwsh-vault-dl ${VERSION} $(generate_spaces 40)" --inputbox "# Enter OTP (Default: None):" 0 0)
    if [ ! -z "${name_otp}" ] ; then
      name_otp=$(spaceForDot "${name_otp}")
      name_otp=$(vault_key_encrypt "${name_otp}")
      otp_text=$(vault_key_encrypt "OTP")
      echo "${masterkey_load}" > "${pwsh_vault}/logins/${name_entry}/otp"
      echo "${otp_text};${name_otp}" >> "${pwsh_vault}/logins/${name_entry}/otp"
      otp_entry=1
    else
      name_otp="None"
      name_otp=$(vault_key_encrypt "${name_otp}")
      otp_text=$(vault_key_encrypt "OTP")
      echo "${masterkey_load}" > "${pwsh_vault}/logins/${name_entry}/otp"
      echo "${otp_text};${name_otp}" >> "${pwsh_vault}/logins/${name_entry}/otp"
      otp_entry=1
    fi
  done
  echo > /dev/null | dialog --title "# pwsh-vault-dl ${VERSION} $(generate_spaces 20)" \
  --progressbox "# Checking New Created Entry \\" 0 0
  name_username=$(vault_key_decrypt "${name_username}")
  name_password=$(vault_key_decrypt "${name_password}")
  name_url=$(vault_key_decrypt "${name_url}")
  name_otp=$(vault_key_decrypt "${name_otp}")
  echo "# ENTRY CREATED:" > ${pwsh_vault_cache_temp}
  echo "" >> ${pwsh_vault_cache_temp}
  echo "# Name Entry: ${name_entry}" >> ${pwsh_vault_cache_temp}
  echo "# Username: ${name_username}" >> ${pwsh_vault_cache_temp}
  echo "# Password: ${name_password}" >> ${pwsh_vault_cache_temp}
  echo "# URL: ${name_url}" >> ${pwsh_vault_cache_temp}
  echo "# OTP: ${name_otp}" >> ${pwsh_vault_cache_temp}
  dialog --title "# pwsh-vault-dl ${VERSION}" --textbox ${pwsh_vault_cache_temp} 0 0
  create_entries_menu
}

function create_bcard_vault_entry() {
  name_bcard_entry=0
  masterkey_load=$(cat ${pwsh_vault_masterkey})
  while [ ${name_bcard_entry} -eq 0 ] ; do
    name_entry=$(dialog --stdout --title "# pwsh-vault-dl ${VERSION} $(generate_spaces 20)" --inputbox "# Enter Name for Bcard Entry:" 0 0)
    if [ ! -z "${name_entry}" ] ; then
      name_entry=$(removeSpaces "${name_entry}")
      if [ -d "${pwsh_vault}/bcard/${name_entry}" ] ; then
        dialog --title "# pwsh-vault-dl ${VERSION} $(generate_spaces 20)" \
        --msgbox "# Vault bcard/${name_entry} already exists\n# You can remove or edit it." 0 0
        pwsh_vault_main
      fi
      mkdir -p "${pwsh_vault}/bcard/${name_entry}"
      name_bcard_entry=1
    fi
  done
  owner_entry=0
  while [ ${owner_entry} -eq 0 ] ; do
    name_owner=$(dialog --stdout --title "# pwsh-vault-dl ${VERSION} $(generate_spaces 30)" --inputbox "# Enter Owner:" 0 0)
    if [ ! -z "${name_owner}" ] ; then
      name_owner=$(removeSpaces "${name_owner}")
      name_owner=$(vault_key_encrypt "${name_owner}")
      owner_text=$(vault_key_encrypt "Owner")
      echo "${masterkey_load}" > "${pwsh_vault}/bcard/${name_entry}/owner"
      echo "${owner_text};${name_owner}" >> "${pwsh_vault}/bcard/${name_entry}/owner"
      owner_entry=1
    fi
  done
  card_entry=0
  while [ ${card_entry} -eq 0 ] ; do
    name_card=$(dialog --stdout --title "# pwsh-vault-dl ${VERSION} $(generate_spaces 40)" --inputbox "# Enter Card Number (XXXX-XXXX-XXXX-XXXX):" 0 0)
    if [ ! -z "${name_card}" ] ; then
      name_card=$(spaceForDot "${name_card}")
      name_card=$(vault_key_encrypt "${name_card}")
      card_text=$(vault_key_encrypt "Card")
      echo "${masterkey_load}" > "${pwsh_vault}/bcard/${name_entry}/card"
      echo "${card_text};${name_card}" >> "${pwsh_vault}/bcard/${name_entry}/card"
      card_entry=1
    fi
  done
  expiry_entry=0
  while [ ${expiry_entry} -eq 0 ] ; do
    name_expiry=$(dialog --stdout --title "# pwsh-vault-dl ${VERSION} $(generate_spaces 20)" --inputbox "# Enter Expiry Date (MM/YY):" 0 0)
    if [ ! -z "${name_expiry}" ] ; then
      name_expiry=$(spaceForDot "${name_expiry}")
      name_expiry=$(vault_key_encrypt "${name_expiry}")
      expiry_text=$(vault_key_encrypt "Expiry")
      echo "${masterkey_load}" > "${pwsh_vault}/bcard/${name_entry}/expiry"
      echo "${expiry_text};${name_expiry}" >> "${pwsh_vault}/bcard/${name_entry}/expiry"
      expiry_entry=1
    fi
  done
  cvv_entry=0
  while [ ${cvv_entry} -eq 0 ] ; do
    name_cvv=$(dialog --stdout --title "# pwsh-vault-dl ${VERSION} $(generate_spaces 20)" --inputbox "# Enter CVV:" 0 0)
    if [ ! -z "${name_cvv}" ] ; then
      name_cvv=$(spaceForDot "${name_cvv}")
      name_cvv=$(vault_key_encrypt "${name_cvv}")
      cvv_text=$(vault_key_encrypt "CVV")
      echo "${masterkey_load}" > "${pwsh_vault}/bcard/${name_entry}/cvv"
      echo "${cvv_text};${name_cvv}" >> "${pwsh_vault}/bcard/${name_entry}/cvv"
      cvv_entry=1
    fi
  done
  name_owner=$(vault_key_decrypt "${name_owner}")
  name_owner=$(restoreSpaces "${name_owner}")
  name_card=$(vault_key_decrypt "${name_card}")
  name_expiry=$(vault_key_decrypt "${name_expiry}")
  name_cvv=$(vault_key_decrypt "${name_cvv}")
  echo "# ENTRY CREATED:" > ${pwsh_vault_cache_temp}
  echo "" >> ${pwsh_vault_cache_temp}
  echo "# Name Entry: ${name_entry}" >> ${pwsh_vault_cache_temp}
  echo "# Owner: ${name_owner}" >> ${pwsh_vault_cache_temp}
  echo "# Card: ${name_card}" >> ${pwsh_vault_cache_temp}
  echo "# Expiry: ${name_expiry}" >> ${pwsh_vault_cache_temp}
  echo "# CVV: ${name_cvv}" >> ${pwsh_vault_cache_temp}
  dialog --title "# pwsh-vault-dl ${VERSION}" --textbox ${pwsh_vault_cache_temp} 0 0
  create_entries_menu
}

function create_note_vault_entry() {
  name_note_entry=0
  masterkey_load=$(cat ${pwsh_vault_masterkey})
  while [ ${name_note_entry} -eq 0 ] ; do
    name_entry=$(dialog --stdout --title "# pwsh-vault-dl ${VERSION} $(generate_spaces 20)" --inputbox "# Enter Name for Note Entry:" 0 0)
    if [ ! -z "${name_entry}" ] ; then
      name_entry=$(removeSpaces "${name_entry}")
      if [ -d "${pwsh_vault}/notes/${name_entry}" ] ; then
        dialog --title "# pwsh-vault-dl ${VERSION} $(generate_spaces 20)" \
        --msgbox "# Vault notes/${name_entry} already exists\n# You can remove or edit it." 0 0
        pwsh_vault_main
      fi
      mkdir -p "${pwsh_vault}/notes/${name_entry}"
      name_note_entry=1
    fi
  done
  note_entry=0
  while [ ${note_entry} -eq 0 ] ; do
    name_note=$(dialog --stdout --title "# pwsh-vault-dl ${VERSION} $(generate_spaces 40)" --inputbox "# Enter Note:" 0 0)
    if [ ! -z "${name_note}" ] ; then
      name_note=$(removeSpaces "${name_note}")
      name_note=$(vault_key_encrypt "${name_note}")
      note_text=$(vault_key_encrypt "Note")
      echo "${masterkey_load}" > "${pwsh_vault}/notes/${name_entry}/note"
      echo "${note_text};${name_note}" >> "${pwsh_vault}/notes/${name_entry}/note"
      note_entry=1
    fi
  done
  name_note=$(vault_key_decrypt "${name_note}")
  name_note=$(restoreSpaces "${name_note}")
  echo "# ENTRY CREATED:" > ${pwsh_vault_cache_temp}
  echo "" >> ${pwsh_vault_cache_temp}
  echo "# Name Entry: ${name_entry}" >> ${pwsh_vault_cache_temp}
  echo "# Note: ${name_note}" >> ${pwsh_vault_cache_temp}
  dialog --title "# pwsh-vault-dl ${VERSION}" --textbox ${pwsh_vault_cache_temp} 0 0
  create_entries_menu
}

function create_entries_menu() {
  new_entry=$(dialog --stdout --menu "# pwsh-vault-dl ${VERSION}" \
  0 0 0 l "Login/Website Entry" b "Credit/Bank Card Entry" n "Note Entry" r "Back")
  if [ "${new_entry}" == "l" ] ; then
    create_login_vault_entry
  elif [ "${new_entry}" == "b" ] ; then
    create_bcard_vault_entry
  elif [ "${new_entry}" == "n" ] ; then
    create_note_vault_entry
  else
    echo > /dev/null
  fi
}

function export_pwsh_vault() {
  name_date=$(date +%Y-%m-%d_%H%M)
  cd ${pwsh_vault}
  dialog --title "# pwsh-vault-dl ${VERSION} $(generate_spaces 20)" --yesno "# Set password when exporting?" 0 0
  export_vault=$?
  if [ "${export_vault}" == "0" ] ; then
    password_export=$(dialog --stdout --title "# pwsh-vault-dl ${VERSION} $(generate_spaces 20)" --passwordbox "# Enter Exporting Password:" 0 0)
    repassword_export=$(dialog --stdout --title "# pwsh-vault-dl ${VERSION} $(generate_spaces 20)" --passwordbox "# Re-Enter Exporting Password:" 0 0)
    if [ "${password_export}" == "${repassword_export}" ] ; then
      zip -P "${password_export}" -r ${HOME}/pwsh-vault-export_${name_date}.zip *
      error=$?
      if [ ${error} -eq 0 ] ; then
        dialog --title "# pwsh-vault-dl ${VERSION} $(generate_spaces 40)" --msgbox "# Vault exported to ${HOME}/pwsh-vault-export_${name_date}.zip" 0 0
      else
        dialog --title "# pwsh-vault-dl ${VERSION} $(generate_spaces 20)" --msgbox "# Error Exporting Vault" 0 0
        rm -rf ${HOME}/pwsh-vault-export_${name_date}.zip
      fi
    else
      dialog --title "# pwsh-vault-dl ${VERSION} $(generate_spaces 20)" --msgbox "# Both passwords do not match" 0 0
    fi
  else
    zip -r ${HOME}/pwsh-vault-export_${name_date}.zip *
    error=$?
    if [ ${error} -eq 0 ] ; then
      dialog --title "# pwsh-vault-dl ${VERSION} $(generate_spaces 40)" --msgbox "# Vault exported to ${HOME}/pwsh-vault-export_${name_date}.zip" 0 0
    else
      dialog --title "# pwsh-vault-dl ${VERSION} $(generate_spaces 20)" --msgbox "# Error Exporting Vault" 0 0
      rm -rf ${HOME}/pwsh-vault-export_${name_date}.zip
    fi
  fi
}

function export_pwsh_vault_param() {
  name_date=$(date +%Y-%m-%d_%H%M)
  cd ${pwsh_vault}
  zip -r ${HOME}/pwsh-vault-export_${name_date}.zip *
  error=$?
  if [ ${error} -eq 0 ] ; then
    echo "# Vault exported to ${HOME}/pwsh-vault-export_${name_date}.zip"
  else
    echo "# Error Exporting Vault"
    rm -rf ${HOME}/pwsh-vault-export_${name_date}.zip
  fi
}

function export_pwsh_vault_param_encrypt() {
  name_date=$(date +%Y-%m-%d_%H%M)
  cd ${pwsh_vault}
  zip -e -r ${HOME}/pwsh-vault-export_${name_date}.zip *
  error=$?
  if [ ${error} -eq 0 ] ; then
    echo "# Vault exported to ${HOME}/pwsh-vault-export_${name_date}.zip"
  else
    echo "# Error Exporting Vault"
    rm -rf ${HOME}/pwsh-vault-export_${name_date}.zip
  fi
}

function import_pwsh_vault() {
  cd ${pwsh_vault}
  zip_file=$(dialog --stdout --title "# pwsh-vault-dl ${VERSION} $(generate_spaces 20)" --inputbox "# Enter path of zip file:" 0 0)
  if [ -f "${zip_file}" ] ; then
    password_import=$(dialog --stdout --title "# pwsh-vault-dl ${VERSION} $(generate_spaces 40)" --passwordbox "# Enter Importing Password (Blank if Does Not Have):" 0 0)
    if [ -z "${password_import}" ] ; then
      password_import="test"
    fi
    unzip -P "${password_import}" -o "${zip_file}" -d ${pwsh_vault}
    error=$?
    if [ ${error} -eq 0 ] ; then
      dialog --title "# pwsh-vault-dl ${VERSION} $(generate_spaces 40)" --msgbox "# Vault imported from ${zip_file}" 0 0
    else
      dialog --title "# pwsh-vault-dl ${VERSION} $(generate_spaces 20)" --msgbox "# Error Importing Vault" 0 0
    fi
  else
    if [ -z "${zip_file}" ] ; then
      echo > /dev/null
    else
      dialog --title "# pwsh-vault-dl ${VERSION} $(generate_spaces 40)" --msgbox "# Vault ${zip_file} does not exist" 0 0
    fi
  fi
}

function import_pwsh_vault_param() {
  if [ -f "${1}" ] ; then
    echo "# Importing vault from zip file"
    unzip -o "${1}" -d ${pwsh_vault}
    error=$?
    if [ ${error} -eq 0 ] ; then
      echo "# Vault Imported from ${1}"
      zip_file_exist=1
    else
      echo "# Error Importing Vault"
      zip_file_exist=1
    fi
  else
    if [ -z "${1}" ] ; then
      pwsh_vault_help
    else
      echo "# Vault ${1} does not exist"
    fi
  fi
}

function pwsh_vault_about() {
    dialog --title "# pwsh-vault-dl ${VERSION} | About" \
    --msgbox "# Software: pwsh-vault-dl ${VERSION}\n# Contact: q3aql <q3aql@duck.com>\n# LICENSE: GPLv2.0" 0 0
}

function pwsh_vault_help() {
    echo ""
    echo "# pwsh-vault-dl ${VERSION}"
    echo ""
    echo "# Usage:"
    echo "  $ pwsh-vault-dl                      --> Run Main CLI"
    echo "  $ pwsh-vault-dl --export [--encrypt] --> Export Vault"
    echo "  $ pwsh-vault-dl --import <path-file> --> Import Vault"
    echo "  $ pwsh-vault-dl --reset              --> Delete all settings"
    echo "  $ pwsh-vault-dl --gen-password [num] --> Generate password"
    echo "  $ pwsh-vault-dl --help               --> Show Help"
    echo ""
    exit
}

function check_corrupted_entry_vault() {
  cd ${pwsh_vault}
  entry_corrupted=0
  if [ -z "${2}" ] ; then
    entry_corrupted=1
  else
    if [ -d "${2}/${1}" ] ; then
      if [ "${2}" == "logins" ] ; then
        check_login=$(cat ${2}/${1}/login | head -1)
        check_password=$(cat ${2}/${1}/password | head -1)
        check_url=$(cat ${2}/${1}/url | head -1)
        check_otp=$(cat ${2}/${1}/otp | head -1)
        check_masterkey=$(cat masterkey 2> /dev/null)
        if [ "${check_login}" != "${check_masterkey}" ] ; then
          entry_corrupted=1
        elif [ "${check_password}" != "${check_masterkey}" ] ; then 
          entry_corrupted=1
        elif [ "${check_url}" != "${check_masterkey}" ] ; then 
          entry_corrupted=1
        elif [ "${check_otp}" != "${check_masterkey}" ] ; then 
          entry_corrupted=1
        else
          entry_corrupted=0
        fi
      elif [ "${2}" == "notes" ] ; then
        check_note=$(cat ${2}/${1}/note | head -1)
        check_masterkey=$(cat masterkey)
        if [ "${check_note}" != "${check_masterkey}" ] ; then
          entry_corrupted=1
        else
          entry_corrupted=0
        fi
      elif [ "${2}" == "bcard" ] ; then
        check_owner=$(cat ${2}/${1}/owner | head -1)
        check_card=$(cat ${2}/${1}/card | head -1)
        check_expiry=$(cat ${2}/${1}/expiry | head -1)
        check_cvv=$(cat ${2}/${1}/cvv | head -1)
        check_masterkey=$(cat masterkey 2>/dev/null)
        if [ "${check_owner}" != "${check_masterkey}" ] ; then
          entry_corrupted=1
        elif [ "${check_card}" != "${check_masterkey}" ] ; then
          entry_corrupted=1
        elif [ "${check_expiry}" != "${check_masterkey}" ] ; then
          entry_corrupted=1
        elif [ "${check_cvv}" != "${check_masterkey}" ] ; then
          entry_corrupted=1
        else
          entry_corrupted=0
        fi
      else
        entry_corrupted=1
      fi
    else
      entry_corrupted=1
    fi
  fi
  echo ${entry_corrupted}
}

function list_entries_vault() {
  echo > /dev/null | dialog --title "# pwsh-vault-dl ${VERSION} $(generate_spaces 20)" \
  --progressbox "# Loading Vault List Entries \\" 0 0
  cd ${pwsh_vault}
  count=1
  list_logins_count=$(ls -1 logins/ | wc -l)
  list_bcard_count=$(ls -1 bcard/ | wc -l)
  list_notes_count=$(ls -1 notes/ | wc -l)
  total_count_vaults=$(expr ${list_logins_count} + ${list_bcard_count} + ${list_notes_count})
  list_entries_vault_dl="dialog --menu '# Vault List Entries (${total_count_vaults}):' 0 0 0"
  if [ ${list_logins_count} -ne 0 ] ; then
    for entry in $(ls -1 logins/) ; do
      list_entries_vault_dl="${list_entries_vault_dl} ${count} \"logins/${entry}\""
      count=$(expr ${count} + 1)
    done
  fi
  cd ${pwsh_vault}
  if [ ${list_bcard_count} -ne 0 ] ; then
    for entry in $(ls -1 bcard/) ; do
      list_entries_vault_dl="${list_entries_vault_dl} ${count} \"bcard/${entry}\""
      count=$(expr ${count} + 1)
    done
  fi
  cd ${pwsh_vault}
  if [ ${list_notes_count} -ne 0 ] ; then
    for entry in $(ls -1 notes/) ; do
      list_entries_vault_dl="${list_entries_vault_dl} ${count} \"notes/${entry}\""
      count=$(expr ${count} + 1)
    done
  fi
  if [ ${total_count_vaults} -eq 0 ] ; then
    dialog --title "# pwsh-vault-dl ${VERSION} $(generate_spaces 20)" --msgbox "# No Entries to Show" 0 0
    pwsh_vault_main
  fi
  echo "${list_entries_vault_dl}" > ${pwsh_vault_cache_temp}
  bash ${pwsh_vault_cache_temp}
  read pepe
}

function change_masterkey_vault() {
  echo > /dev/null | dialog --title "# pwsh-vault-dl ${VERSION} $(generate_spaces 20)" \
  --progressbox "# Loading Section For Change MasterKey \\" 0 0
  load_masterkey=$(cat ${pwsh_vault_masterkey} | cut -d ";" -f 2)
  masterkey_loaded=$(vault_key_decrypt "${load_masterkey}")
  count_logins=$(ls -1 ${pwsh_vault}/logins/ | wc -l)
  count_notes=$(ls -1 ${pwsh_vault}/notes/ | wc -l)
  count_bcard=$(ls -1 ${pwsh_vault}/bcard/ | wc -l)
  current_masterkey=$(dialog --stdout --title "# pwsh-vault-dl ${VERSION} $(generate_spaces 20)" --passwordbox "# Enter Current MasterKey:" 0 0)
  if [ "${current_masterkey}" == "${masterkey_loaded}" ] ; then
    masterkey_input=$(dialog --stdout --title "# pwsh-vault-dl ${VERSION} $(generate_spaces 20)" --passwordbox "# Enter New MasterKey:" 0 0)
    masterkey_reinput=$(dialog --stdout --title "# pwsh-vault-dl ${VERSION} $(generate_spaces 20)" --passwordbox "# Re-Enter New MasterKey:" 0 0)
    if [ "${masterkey_input}" == "${masterkey_reinput}" ] ; then
      masterkey_name=$(vault_key_encrypt "Masterkey")
      masterkey_gen=$(vault_key_encrypt "${masterkey_input}")
      echo "${masterkey_name};${masterkey_gen}" > ${pwsh_vault_masterkey}
      echo > /dev/null | dialog --title "# pwsh-vault-dl ${VERSION} $(generate_spaces 30)" \
      --progressbox "# Applying the change in ${pwsh_vault}/logins vaults" 0 0
      if [ ${count_logins} -ne 0 ] ; then
        list_logins=$(ls -1 ${pwsh_vault}/logins/)
        for login in ${list_logins} ; do
          login_content=$(cat ${pwsh_vault}/logins/${login}/login | tail -1)
          echo "${masterkey_name};${masterkey_gen}" > ${pwsh_vault}/logins/${login}/login
          echo "${login_content}" >> ${pwsh_vault}/logins/${login}/login
          password_content=$(cat ${pwsh_vault}/logins/${login}/password | tail -1)
          echo "${masterkey_name};${masterkey_gen}" > ${pwsh_vault}/logins/${login}/password
          echo "${password_content}" >> ${pwsh_vault}/logins/${login}/password
          url_content=$(cat ${pwsh_vault}/logins/${login}/url | tail -1)
          echo "${masterkey_name};${masterkey_gen}" > ${pwsh_vault}/logins/${login}/url
          echo "${url_content}" >> ${pwsh_vault}/logins/${login}/url
          otp_content=$(cat ${pwsh_vault}/logins/${login}/otp | tail -1)
          echo "${masterkey_name};${masterkey_gen}" > ${pwsh_vault}/logins/${login}/otp
          echo "${otp_content}" >> ${pwsh_vault}/logins/${login}/otp
        done
      fi
      echo > /dev/null | dialog --title "# pwsh-vault-dl ${VERSION} $(generate_spaces 30)" \
      --progressbox "# Applying the change in ${pwsh_vault}/bcard vaults" 0 0
      if [ ${count_bcard} -ne 0 ] ; then
        list_bcard=$(ls -1 ${pwsh_vault}/bcard/)
        for card in ${list_bcard} ; do
          owner_content=$(cat ${pwsh_vault}/bcard/${card}/owner | tail -1)
          echo "${masterkey_name};${masterkey_gen}" > ${pwsh_vault}/bcard/${card}/owner
          echo "${owner_content}" >> ${pwsh_vault}/bcard/${card}/owner
          card_content=$(cat ${pwsh_vault}/bcard/${card}/card | tail -1)
          echo "${masterkey_name};${masterkey_gen}" > ${pwsh_vault}/bcard/${card}/card
          echo "${card_content}" >> ${pwsh_vault}/bcard/${card}/card
          expiry_content=$(cat ${pwsh_vault}/bcard/${card}/expiry | tail -1)
          echo "${masterkey_name};${masterkey_gen}" > ${pwsh_vault}/bcard/${card}/expiry
          echo "${expiry_content}" >> ${pwsh_vault}/bcard/${card}/expiry
          cvv_content=$(cat ${pwsh_vault}/bcard/${card}/cvv | tail -1)
          echo "${masterkey_name};${masterkey_gen}" > ${pwsh_vault}/bcard/${card}/cvv
          echo "${cvv_content}" >> ${pwsh_vault}/bcard/${card}/cvv
        done
      fi
      echo > /dev/null | dialog --title "# pwsh-vault-dl ${VERSION} $(generate_spaces 30)" \
      --progressbox "# Applying the change in ${pwsh_vault}/notes vaults" 0 0
      if [ ${count_notes} -ne 0 ] ; then
        list_notes=$(ls -1 ${pwsh_vault}/notes/)
        for note in ${list_notes} ; do
          note_content=$(cat ${pwsh_vault}/notes/${note}/note | tail -1)
          echo "${masterkey_name};${masterkey_gen}" > ${pwsh_vault}/notes/${note}/note
          echo "${note_content}" >> ${pwsh_vault}/notes/${note}/note
        done
      fi
      dialog --title "# pwsh-vault-dl ${VERSION} $(generate_spaces 20)" --msgbox "# New MasterKey configuration finished" 0 0
    else
      dialog --title "# pwsh-vault-dl ${VERSION} $(generate_spaces 20)" --msgbox "# Both passwords do not match" 0 0
    fi
  else
    dialog --title "# pwsh-vault-dl ${VERSION} $(generate_spaces 20)" --msgbox "# Wrong MasterKey" 0 0
  fi
}

function remove_entry_vault() {
  echo > /dev/null | dialog --title "# pwsh-vault-dl ${VERSION} $(generate_spaces 20)" \
  --progressbox "# Loading Vault List Entries \\" 0 0
  count_logins=$(ls -1 ${pwsh_vault}/logins/ | wc -l)
  count_notes=$(ls -1 ${pwsh_vault}/notes/ | wc -l)
  count_bcard=$(ls -1 ${pwsh_vault}/bcard/ | wc -l)
  count_total=$(expr ${count_logins} + ${count_notes} + ${count_bcard})
  list_entries_vault_dl="dialog --stdout --menu '# Vault List Entries (${count_total}):' 0 0 0"
  if [ ${count_logins} -ne 0 ] ; then
    list_logins=$(ls -1 ${pwsh_vault}/logins/)
    for login in ${list_logins} ; do
      list_entries_vault_dl="${list_entries_vault_dl} \"logins/${login}\" L"
    done
  fi
  if [ ${count_notes} -ne 0 ] ; then
    list_notes=$(ls -1 ${pwsh_vault}/notes/)
    for note in ${list_notes} ; do
      list_entries_vault_dl="${list_entries_vault_dl} \"notes/${note}\" N"
    done
  fi
  if [ ${count_bcard} -ne 0 ] ; then
    list_bcard=$(ls -1 ${pwsh_vault}/bcard/)
    for card in ${list_bcard} ; do
      list_entries_vault_dl="${list_entries_vault_dl} \"bcard/${card}\" B"
    done
  fi
  if [ ${count_total} -eq 0 ] ; then
    dialog --title "# pwsh-vault-dl ${VERSION} $(generate_spaces 20)" --msgbox "# No Entries to Show" 0 0
    pwsh_vault_main
  fi
  echo "${list_entries_vault_dl}" > ${pwsh_vault_cache_temp}
  vault_remove_entry=$(bash ${pwsh_vault_cache_temp})
  if [ -z "${vault_remove_entry}" ] ; then
    echo > /dev/null
  else
    if [ -d "${pwsh_vault}/${vault_remove_entry}" ] ; then
      echo ""
      dialog --title "# Selected Entry ${vault_remove_entry}" --yesno "# Are you sure?" 0 0
      are_you_sure=$?
      if [ "${are_you_sure}" == "0" ] ; then
        echo > /dev/null | dialog --title "# pwsh-vault-dl ${VERSION} $(generate_spaces 20)" \
        --progressbox "# Removing ${vault_remove_entry} Entry \\" 0 0
        rm -rf "${pwsh_vault}/${vault_remove_entry}"
        dialog --title "# pwsh-vault-dl ${VERSION} $(generate_spaces 20)" --msgbox "# Entry ${vault_remove_entry} Removed" 0 0
        remove_entry_vault
      else
        remove_entry_vault
      fi
    else
      dialog --title "# pwsh-vault-dl ${VERSION} $(generate_spaces 20)" --msgbox "# Entry ${vault_remove_entry} does no exist" 0 0
      remove_entry_vault
    fi
  fi
}

function edit_entry_vault() {
  echo > /dev/null | dialog --title "# pwsh-vault-dl ${VERSION} $(generate_spaces 20)" \
  --progressbox "# Loading Vault List Entries \\" 0 0
  count_logins=$(ls -1 ${pwsh_vault}/logins/ | wc -l)
  count_notes=$(ls -1 ${pwsh_vault}/notes/ | wc -l)
  count_bcard=$(ls -1 ${pwsh_vault}/bcard/ | wc -l)
  count_total=$(expr ${count_logins} + ${count_notes} + ${count_bcard})
  list_entries_vault_dl="dialog --stdout --menu '# Vault List Entries (${count_total}):' 0 0 0"
  if [ ${count_logins} -ne 0 ] ; then
    list_logins=$(ls -1 ${pwsh_vault}/logins/)
    for login in ${list_logins} ; do
      list_entries_vault_dl="${list_entries_vault_dl} \"logins/${login}\" L"
    done
  fi
  if [ ${count_notes} -ne 0 ] ; then
    list_notes=$(ls -1 ${pwsh_vault}/notes/)
    for note in ${list_notes} ; do
      list_entries_vault_dl="${list_entries_vault_dl} \"notes/${note}\" N"
    done
  fi
  if [ ${count_bcard} -ne 0 ] ; then
    list_bcard=$(ls -1 ${pwsh_vault}/bcard/)
    for card in ${list_bcard} ; do
      list_entries_vault_dl="${list_entries_vault_dl} \"bcard/${card}\" B"
    done
  fi
  if [ ${count_total} -eq 0 ] ; then
    dialog --title "# pwsh-vault-dl ${VERSION} $(generate_spaces 20)" --msgbox "# No Entries to Show" 0 0
    pwsh_vault_main
  fi
  echo "${list_entries_vault_dl}" > ${pwsh_vault_cache_temp}
  vault_edit_entry=$(bash ${pwsh_vault_cache_temp})
  if [ -z "${vault_edit_entry}" ] ; then
    echo > /dev/null
  else
    if [ -d "${pwsh_vault}/${vault_edit_entry}" ] ; then
      echo > /dev/null | dialog --title "# pwsh-vault-dl ${VERSION} $(generate_spaces 20)" \
      --progressbox "# Preparing For ${pwsh_vault}/${vault_edit_entry} Editing \\" 0 0
      masterkey_load=$(cat ${pwsh_vault_masterkey})
      if [ -f "${pwsh_vault}/${vault_edit_entry}/login" ] ; then
        read_username=$(cat ${pwsh_vault}/${vault_edit_entry}/login | tail -1 | cut -d ";" -f 2)
        read_userame_dc=$(vault_key_decrypt "${read_username}")
        name_username=$(dialog --stdout --title "# Selected Entry ${vault_edit_entry} $(generate_spaces 20)" --inputbox "# Enter Username (Default: ${read_userame_dc}):" 0 0)
        if [ ! -z "${name_username}" ] ; then
          name_username=$(spaceForDot "${name_username}")
          name_username=$(vault_key_encrypt "${name_username}")
          username_text=$(vault_key_encrypt "Username")
          echo "${masterkey_load}" > "${pwsh_vault}/${vault_edit_entry}/login"
          echo "${username_text};${name_username}" >> "${pwsh_vault}/${vault_edit_entry}/login"
        fi
      fi
      if [ -f "${pwsh_vault}/${vault_edit_entry}/password" ] ; then
        read_password=$(cat ${pwsh_vault}/${vault_edit_entry}/password | tail -1 | cut -d ";" -f 2)
        read_password_dc=$(vault_key_decrypt "${read_password}")
        name_password=$(dialog --stdout --title "# Selected Entry ${vault_edit_entry} $(generate_spaces 20)" --inputbox "# Enter Password (Default: ${read_password_dc}):" 0 0)
        if [ ! -z "${name_password}" ] ; then
          name_password=$(spaceForDot "${name_password}")
          name_password=$(vault_key_encrypt "${name_password}")
          password_text=$(vault_key_encrypt "Password")
          echo "${masterkey_load}" > "${pwsh_vault}/${vault_edit_entry}/password"
          echo "${password_text};${name_password}" >> "${pwsh_vault}/${vault_edit_entry}/password"
        fi
      fi
      if [ -f "${pwsh_vault}/${vault_edit_entry}/url" ] ; then
        read_url=$(cat ${pwsh_vault}/${vault_edit_entry}/url | tail -1 | cut -d ";" -f 2)
        read_url_dc=$(vault_key_decrypt "${read_url}")
        name_url=$(dialog --stdout --title "# Selected Entry ${vault_edit_entry} $(generate_spaces 40)" --inputbox "# Enter URL (Default: ${read_url_dc}):" 0 0)
        if [ ! -z "${name_url}" ] ; then
          name_url=$(removeSpacesURL "${name_url}")
          name_url=$(vault_key_encrypt "${name_url}")
          url_text=$(vault_key_encrypt "URL")
          echo "${masterkey_load}" > "${pwsh_vault}/${vault_edit_entry}/url"
          echo "${url_text};${name_url}" >> "${pwsh_vault}/${vault_edit_entry}/url"
        fi
      fi
      if [ -f "${pwsh_vault}/${vault_edit_entry}/otp" ] ; then
        read_otp=$(cat ${pwsh_vault}/${vault_edit_entry}/otp | tail -1 | cut -d ";" -f 2)
        read_otp_dc=$(vault_key_decrypt "${read_otp}")
        name_otp=$(dialog --stdout --title "# Selected Entry ${vault_edit_entry} $(generate_spaces 40)" --inputbox "# Enter OTP (Default: ${read_otp_dc}):" 0 0)
        if [ ! -z "${name_otp}" ] ; then
          name_otp=$(spaceForDot "${name_otp}")
          name_otp=$(vault_key_encrypt "${name_otp}")
          otp_text=$(vault_key_encrypt "OTP")
          echo "${masterkey_load}" > "${pwsh_vault}/${vault_edit_entry}/otp"
          echo "${otp_text};${name_otp}" >> "${pwsh_vault}/${vault_edit_entry}/otp"
        fi
      fi
      if [ -f "${pwsh_vault}/${vault_edit_entry}/owner" ] ; then
        read_owner=$(cat ${pwsh_vault}/${vault_edit_entry}/owner | tail -1 | cut -d ";" -f 2)
        read_owner_dc=$(vault_key_decrypt "${read_owner}")
        read_owner_dc=$(restoreSpaces "${read_owner_dc}")
        name_owner=$(dialog --stdout --title "# Selected Entry ${vault_edit_entry} $(generate_spaces 40)" --inputbox "# Enter Owner (Default: ${read_owner_dc}):" 0 0)
        if [ ! -z "${name_owner}" ] ; then
          name_owner=$(removeSpaces "${name_owner}")
          name_owner=$(vault_key_encrypt "${name_owner}")
          owner_text=$(vault_key_encrypt "Owner")
          echo "${masterkey_load}" > "${pwsh_vault}/${vault_edit_entry}/owner"
          echo "${owner_text};${name_owner}" >> "${pwsh_vault}/${vault_edit_entry}/owner"
        fi
      fi
      if [ -f "${pwsh_vault}/${vault_edit_entry}/card" ] ; then
        read_card=$(cat ${pwsh_vault}/${vault_edit_entry}/card | tail -1 | cut -d ";" -f 2)
        read_card_dc=$(vault_key_decrypt "${read_card}")
        name_card=$(dialog --stdout --title "# Selected Entry ${vault_edit_entry} $(generate_spaces 40)" --inputbox "# Enter Card Number (Default: ${read_card_dc}):" 0 0)
        if [ ! -z "${name_card}" ] ; then
          name_card=$(spaceForDot "${name_card}")
          name_card=$(vault_key_encrypt "${name_card}")
          card_text=$(vault_key_encrypt "Card")
          echo "${masterkey_load}" > "${pwsh_vault}/${vault_edit_entry}/card"
          echo "${card_text};${name_card}" >> "${pwsh_vault}/${vault_edit_entry}/card"
        fi
      fi
      if [ -f "${pwsh_vault}/${vault_edit_entry}/expiry" ] ; then
        read_expiry=$(cat ${pwsh_vault}/${vault_edit_entry}/expiry | tail -1 | cut -d ";" -f 2)
        read_expiry_dc=$(vault_key_decrypt "${read_expiry}")
        name_expiry=$(dialog --stdout --title "# Selected Entry ${vault_edit_entry} $(generate_spaces 20)" --inputbox "# Enter Expiry Date (Default: ${read_expiry_dc}):" 0 0)
        if [ ! -z "${name_expiry}" ] ; then
          name_expiry=$(spaceForDot "${name_expiry}")
          name_expiry=$(vault_key_encrypt "${name_expiry}")
          expiry_text=$(vault_key_encrypt "Expiry")
          echo "${masterkey_load}" > "${pwsh_vault}/${vault_edit_entry}/expiry"
          echo "${expiry_text};${name_expiry}" >> "${pwsh_vault}/${vault_edit_entry}/expiry"
        fi
      fi
      if [ -f "${pwsh_vault}/${vault_edit_entry}/cvv" ] ; then
        read_cvv=$(cat ${pwsh_vault}/${vault_edit_entry}/cvv | tail -1 | cut -d ";" -f 2)
        read_cvv_dc=$(vault_key_decrypt "${read_cvv}")
        name_cvv=$(dialog --stdout --title "# Selected Entry ${vault_edit_entry} $(generate_spaces 20)" --inputbox "# Enter CVV (Default: ${read_cvv_dc}):" 0 0)
        if [ ! -z "${name_cvv}" ] ; then
          name_cvv=$(spaceForDot "${name_cvv}")
          name_cvv=$(vault_key_encrypt "${name_cvv}")
          cvv_text=$(vault_key_encrypt "cvv")
          echo "${masterkey_load}" > "${pwsh_vault}/${vault_edit_entry}/cvv"
          echo "${cvv_text};${name_cvv}" >> "${pwsh_vault}/${vault_edit_entry}/cvv"
        fi
      fi
      if [ -f "${pwsh_vault}/${vault_edit_entry}/note" ] ; then
        read_note=$(cat ${pwsh_vault}/${vault_edit_entry}/note | tail -1 | cut -d ";" -f 2)
        read_note_dc=$(vault_key_decrypt "${read_note}")
        read_note_dc=$(restoreSpaces "${read_note_dc}")
        name_note=$(dialog --stdout --title "# Selected Entry ${vault_edit_entry} $(generate_spaces 40)" --inputbox "# Enter Note (Default: ${read_note_dc}):" 0 0)
        if [ ! -z "${name_note}" ] ; then
          name_note=$(removeSpaces "${name_note}")
          name_note=$(vault_key_encrypt "${name_note}")
          note_text=$(vault_key_encrypt "note")
          echo "${masterkey_load}" > "${pwsh_vault}/${vault_edit_entry}/note"
          echo "${note_text};${name_note}" >> "${pwsh_vault}/${vault_edit_entry}/note"
        fi
      fi
      dialog --title "# pwsh-vault-dl ${VERSION} $(generate_spaces 20)" --msgbox "# ENTRY ${vault_edit_entry} EDITED" 0 0
      edit_entry_vault
    else
      echo > /dev/null
      edit_entry_vault
    fi
  fi
}

function search_entries_vault() {
  echo > /dev/null | dialog --title "# pwsh-vault-dl ${VERSION} $(generate_spaces 20)" \
  --progressbox "# Loading Search List Entries \\" 0 0
  cd ${pwsh_vault}
  rm -rf ${pwsh_vault_cache_logins}
  rm -rf ${pwsh_vault_cache_logins_otp}
  rm -rf ${pwsh_vault_cache_bcard}
  rm -rf ${pwsh_vault_cache_notes}
  list_logins_count=$(ls -1 logins/ | wc -l)
  list_bcard_count=$(ls -1 bcard/ | wc -l)
  list_notes_count=$(ls -1 notes/ | wc -l)
  total_count_vaults=$(expr ${list_logins_count} + ${list_bcard_count} + ${list_notes_count})
  if [ ${list_logins_count} -ne 0 ] ; then
    list_logins=$(ls -1 logins/)
    for login in ${list_logins} ; do
      echo "logins/${login}" >> ${pwsh_vault_cache_logins_otp}
      echo "logins/${login}" >> ${pwsh_vault_cache_logins}
    done
  fi
  cd ${pwsh_vault}
  if [ ${list_bcard_count} -ne 0 ] ; then
    list_bcard=$(ls -1 bcard/)
    for card in ${list_bcard} ; do
      echo "bcard/${card}" >> ${pwsh_vault_cache_bcard}
    done
  fi
  cd ${pwsh_vault}
  if [ ${list_notes_count} -ne 0 ] ; then
    list_notes=$(ls -1 notes/)
    for note in ${list_notes} ; do
      echo "notes/${note}" >> ${pwsh_vault_cache_notes}
    done
  fi
  search_entry=$(dialog --stdout --menu "# pwsh-vault-dl ${VERSION}" \
  0 0 0 l "Search Login/Website Entry" o "Search Login/Website Entry (Show OTP)" \
  b "Search Credit/Bank Card Entry" n "Search Note Entry" r "Back")
  if [ "${search_entry}" == "l" ] ; then
    string_search=$(dialog --stdout --title "# pwsh-vault-dl ${VERSION} $(generate_spaces 40)" --inputbox "# Type a string to search:" 0 0)
    echo > /dev/null | dialog --title "# pwsh-vault-dl ${VERSION} $(generate_spaces 20)" \
    --progressbox "# Applying Search Filter To Entries \\" 0 0
    if [ -z "${string_search}" ] ; then
      rm -rf ${pwsh_vault_cache_temp}
      touch ${pwsh_vault_cache_temp}
      touch ${pwsh_vault_cache_logins}
      cat ${pwsh_vault_cache_logins} > ${pwsh_vault_cache_temp}
      cat ${pwsh_vault_cache_temp} > ${pwsh_vault_cache_logins}
      lines_read=$(cat ${pwsh_vault_cache_logins} 2> /dev/null | wc -l)
      if [ ${lines_read} -eq 0 ] ; then
        dialog --title "# pwsh-vault-dl ${VERSION} $(generate_spaces 20)" --msgbox "# No Entries to Show" 0 0
      else
        list_entries_vault_dl="dialog --stdout --menu '# Result Vault List Entries:' 0 0 0"
        count=1
        for show in $(cat ${pwsh_vault_cache_logins}) ; do
          list_entries_vault_dl="${list_entries_vault_dl} ${count} \"${show}\""
          count=$(expr ${count} + 1)
        done
        echo "${list_entries_vault_dl}" > ${pwsh_vault_cache_temp}
        search_show_entry=$(bash ${pwsh_vault_cache_temp})
        if [ -z "${search_show_entry}" ] ; then
          echo > /dev/null
        else
          echo > /dev/null | dialog --title "# pwsh-vault-dl ${VERSION} $(generate_spaces 20)" \
          --progressbox "# Decrypting Entry Number ${search_show_entry} \\" 0 0
          expr ${search_show_entry} + 1 &> /dev/null
          error=$?
          if [ ${error} -eq 0 ] ; then
            result=$(cat ${pwsh_vault_cache_logins} | head -${search_show_entry} 2>/dev/null | tail -1 | cut -d "," -f 1 | cut -d "/" -f 2)
            corrupted_result=$(check_corrupted_entry_vault ${result} logins)
            if [ ${corrupted_result} -eq 0 ] ; then
              username_decrypt=$(cat logins/${result}/login | tail -1 | cut -d ";" -f 2)
              username_decrypt=$(vault_key_decrypt "${username_decrypt}")
              password_decrypt=$(cat logins/${result}/password | tail -1 | cut -d ";" -f 2)
              password_decrypt=$(vault_key_decrypt "${password_decrypt}")
              url_decrypt=$(cat logins/${result}/url | tail -1 | cut -d ";" -f 2)
              url_decrypt=$(vault_key_decrypt "${url_decrypt}")
              otp_decrypt=$(cat logins/${result}/otp | tail -1 | cut -d ";" -f 2)
              otp_decrypt=$(vault_key_decrypt "${otp_decrypt}")
              if [ "${otp_decrypt}" == "None" ] ; then
                otp_decrypt="None"
              else
                otp_decrypt="Yes"
              fi
              echo "" >> ${pwsh_vault_clipboard_copy}
              echo "* Name Entry: logins/${result}" >> ${pwsh_vault_clipboard_copy}
              echo "* Login: ${username_decrypt}" >> ${pwsh_vault_clipboard_copy}
              echo "* Password: ${password_decrypt}" >> ${pwsh_vault_clipboard_copy}
              echo "* URL: ${url_decrypt}" >> ${pwsh_vault_clipboard_copy}
              echo "* OTP: ${otp_decrypt}" >> ${pwsh_vault_clipboard_copy}
              echo "* Name Entry: logins/${result}" > ${pwsh_vault_cache_temp}
              echo "* Login: ${username_decrypt}" >> ${pwsh_vault_cache_temp}
              echo "* Password: ${password_decrypt}" >> ${pwsh_vault_cache_temp}
              echo "* URL: ${url_decrypt}" >> ${pwsh_vault_cache_temp}
              echo "* OTP: ${otp_decrypt}" >> ${pwsh_vault_cache_temp}
              echo "" >> ${pwsh_vault_cache_temp}
              echo "* Data has been copied to ${pwsh_vault_clipboard_copy}" >> ${pwsh_vault_cache_temp}
              dialog --title "# pwsh-vault-dl ${VERSION}" --textbox ${pwsh_vault_cache_temp} 0 0
            else
              dialog --title "# pwsh-vault-dl ${VERSION} $(generate_spaces 20)" --msgbox "# Entry logins/${result} CORRUPTED" 0 0
            fi
          fi
        fi
      fi
      rm -rf ${pwsh_vault_cache_logins}
      search_entries_vault
    else
      rm -rf ${pwsh_vault_cache_temp}
      touch ${pwsh_vault_cache_temp}
      touch ${pwsh_vault_cache_logins}
      cat ${pwsh_vault_cache_logins} | grep -i "${string_search}" >> ${pwsh_vault_cache_temp}
      cat ${pwsh_vault_cache_temp} > ${pwsh_vault_cache_logins}
      lines_read=$(cat ${pwsh_vault_cache_logins} 2> /dev/null | wc -l)
      if [ ${lines_read} -eq 0 ] ; then
        dialog --title "# pwsh-vault-dl ${VERSION} $(generate_spaces 20)" --msgbox "# No Entries to Show" 0 0
      else
         list_entries_vault_dl="dialog --stdout --menu '# Result Vault List Entries:' 0 0 0"
        count=1
        for show in $(cat ${pwsh_vault_cache_logins}) ; do
          list_entries_vault_dl="${list_entries_vault_dl} ${count} \"${show}\""
          count=$(expr ${count} + 1)
        done
        echo "${list_entries_vault_dl}" > ${pwsh_vault_cache_temp}
        search_show_entry=$(bash ${pwsh_vault_cache_temp})
        if [ -z "${search_show_entry}" ] ; then
          echo > /dev/null
        else
          echo > /dev/null | dialog --title "# pwsh-vault-dl ${VERSION} $(generate_spaces 20)" \
          --progressbox "# Decrypting Entry Number ${search_show_entry} \\" 0 0
          expr ${search_show_entry} + 1 &> /dev/null
          error=$?
          if [ ${error} -eq 0 ] ; then
            result=$(cat ${pwsh_vault_cache_logins} | head -${search_show_entry} 2>/dev/null | tail -1 | cut -d "," -f 1 | cut -d "/" -f 2)
            corrupted_result=$(check_corrupted_entry_vault ${result} logins)
            if [ ${corrupted_result} -eq 0 ] ; then
              username_decrypt=$(cat logins/${result}/login | tail -1 | cut -d ";" -f 2)
              username_decrypt=$(vault_key_decrypt "${username_decrypt}")
              password_decrypt=$(cat logins/${result}/password | tail -1 | cut -d ";" -f 2)
              password_decrypt=$(vault_key_decrypt "${password_decrypt}")
              url_decrypt=$(cat logins/${result}/url | tail -1 | cut -d ";" -f 2)
              url_decrypt=$(vault_key_decrypt "${url_decrypt}")
              otp_decrypt=$(cat logins/${result}/otp | tail -1 | cut -d ";" -f 2)
              otp_decrypt=$(vault_key_decrypt "${otp_decrypt}")
              if [ "${otp_decrypt}" == "None" ] ; then
                otp_decrypt="None"
              else
                otp_decrypt="Yes"
              fi
              echo "" >> ${pwsh_vault_clipboard_copy}
              echo "* Name Entry: logins/${result}" >> ${pwsh_vault_clipboard_copy}
              echo "* Login: ${username_decrypt}" >> ${pwsh_vault_clipboard_copy}
              echo "* Password: ${password_decrypt}" >> ${pwsh_vault_clipboard_copy}
              echo "* URL: ${url_decrypt}" >> ${pwsh_vault_clipboard_copy}
              echo "* OTP: ${otp_decrypt}" >> ${pwsh_vault_clipboard_copy}
              echo "* Name Entry: logins/${result}" > ${pwsh_vault_cache_temp}
              echo "* Login: ${username_decrypt}" >> ${pwsh_vault_cache_temp}
              echo "* Password: ${password_decrypt}" >> ${pwsh_vault_cache_temp}
              echo "* URL: ${url_decrypt}" >> ${pwsh_vault_cache_temp}
              echo "* OTP: ${otp_decrypt}" >> ${pwsh_vault_cache_temp}
              echo "" >> ${pwsh_vault_cache_temp}
              echo "* Data has been copied to ${pwsh_vault_clipboard_copy}" >> ${pwsh_vault_cache_temp}
              dialog --title "# pwsh-vault-dl ${VERSION}" --textbox ${pwsh_vault_cache_temp} 0 0
            else
              dialog --title "# pwsh-vault-dl ${VERSION} $(generate_spaces 20)" --msgbox "# Entry logins/${result} CORRUPTED" 0 0
            fi
          fi
        fi
      fi
      rm -rf ${pwsh_vault_cache_logins}
      search_entries_vault
    fi
  elif [ "${search_entry}" == "o" ] ; then
    string_search=$(dialog --stdout --title "# pwsh-vault-dl ${VERSION} $(generate_spaces 40)" --inputbox "# Type a string to search:" 0 0)
    echo > /dev/null | dialog --title "# pwsh-vault-dl ${VERSION} $(generate_spaces 20)" \
    --progressbox "# Applying Search Filter To Entries \\" 0 0
    if [ -z "${string_search}" ] ; then
      rm -rf ${pwsh_vault_cache_temp}
      touch ${pwsh_vault_cache_temp}
      touch ${pwsh_vault_cache_logins}
      touch ${pwsh_vault_cache_logins_otp}
      cat ${pwsh_vault_cache_logins_otp} >> ${pwsh_vault_cache_temp}
      cat ${pwsh_vault_cache_temp} > ${pwsh_vault_cache_logins}
      lines_read=$(cat ${pwsh_vault_cache_logins} 2> /dev/null | wc -l)
      if [ ${lines_read} -eq 0 ] ; then
        dialog --title "# pwsh-vault-dl ${VERSION} $(generate_spaces 20)" --msgbox "# No Entries to Show" 0 0
      else
        list_entries_vault_dl="dialog --stdout --menu '# Result Vault List Entries:' 0 0 0"
        count=1
        for show in $(cat ${pwsh_vault_cache_logins}) ; do
          list_entries_vault_dl="${list_entries_vault_dl} ${count} \"${show}\""
          count=$(expr ${count} + 1)
        done
        echo "${list_entries_vault_dl}" > ${pwsh_vault_cache_temp}
        search_show_entry=$(bash ${pwsh_vault_cache_temp})
        if [ -z "${search_show_entry}" ] ; then
          echo > /dev/null
        else
          echo > /dev/null | dialog --title "# pwsh-vault-dl ${VERSION} $(generate_spaces 20)" \
          --progressbox "# Decrypting Entry Number ${search_show_entry} \\" 0 0
          expr ${search_show_entry} + 1 &> /dev/null
          error=$?
          if [ ${error} -eq 0 ] ; then
            result=$(cat ${pwsh_vault_cache_logins} | head -${search_show_entry} 2>/dev/null | tail -1 | cut -d "," -f 1 | cut -d "/" -f 2)
            corrupted_result=$(check_corrupted_entry_vault ${result} logins)
            if [ ${corrupted_result} -eq 0 ] ; then
              username_decrypt=$(cat logins/${result}/login | tail -1 | cut -d ";" -f 2)
              username_decrypt=$(vault_key_decrypt "${username_decrypt}")
              password_decrypt=$(cat logins/${result}/password | tail -1 | cut -d ";" -f 2)
              password_decrypt=$(vault_key_decrypt "${password_decrypt}")
              url_decrypt=$(cat logins/${result}/url | tail -1 | cut -d ";" -f 2)
              url_decrypt=$(vault_key_decrypt "${url_decrypt}")
              otp_decrypt=$(cat logins/${result}/otp | tail -1 | cut -d ";" -f 2)
              otp_decrypt=$(vault_key_decrypt "${otp_decrypt}")
              echo "" >> ${pwsh_vault_clipboard_copy}
              echo "* Name Entry: logins/${result}" >> ${pwsh_vault_clipboard_copy}
              echo "* Login: ${username_decrypt}" >> ${pwsh_vault_clipboard_copy}
              echo "* Password: ${password_decrypt}" >> ${pwsh_vault_clipboard_copy}
              echo "* URL: ${url_decrypt}" >> ${pwsh_vault_clipboard_copy}
              echo "* OTP: ${otp_decrypt}" >> ${pwsh_vault_clipboard_copy}
              echo "* Name Entry: logins/${result}" > ${pwsh_vault_cache_temp}
              echo "* Login: ${username_decrypt}" >> ${pwsh_vault_cache_temp}
              echo "* Password: ${password_decrypt}" >> ${pwsh_vault_cache_temp}
              echo "* URL: ${url_decrypt}" >> ${pwsh_vault_cache_temp}
              echo "* OTP: ${otp_decrypt}" >> ${pwsh_vault_cache_temp}
              echo "" >> ${pwsh_vault_cache_temp}
              echo "* Data has been copied to ${pwsh_vault_clipboard_copy}" >> ${pwsh_vault_cache_temp}
              dialog --title "# pwsh-vault-dl ${VERSION}" --textbox ${pwsh_vault_cache_temp} 0 0
            else
              dialog --title "# pwsh-vault-dl ${VERSION} $(generate_spaces 20)" --msgbox "# Entry logins/${result} CORRUPTED" 0 0
            fi
          fi
        fi
      fi
      rm -rf ${pwsh_vault_cache_logins}
      rm -rf ${pwsh_vault_cache_logins_otp}
      search_entries_vault
    else
      rm -rf ${pwsh_vault_cache_temp}
      touch ${pwsh_vault_cache_temp}
      touch ${pwsh_vault_cache_logins}
      touch ${pwsh_vault_cache_logins_otp}
      cat ${pwsh_vault_cache_logins_otp} | grep -i "${string_search}" >> ${pwsh_vault_cache_temp}
      cat ${pwsh_vault_cache_temp} > ${pwsh_vault_cache_logins}
      lines_read=$(cat ${pwsh_vault_cache_logins} 2> /dev/null | wc -l)
      if [ ${lines_read} -eq 0 ] ; then
        dialog --title "# pwsh-vault-dl ${VERSION} $(generate_spaces 20)" --msgbox "# No Entries to Show" 0 0
      else
        list_entries_vault_dl="dialog --stdout --menu '# Result Vault List Entries:' 0 0 0"
        count=1
        for show in $(cat ${pwsh_vault_cache_logins}) ; do
          list_entries_vault_dl="${list_entries_vault_dl} ${count} \"${show}\""
          count=$(expr ${count} + 1)
        done
        echo "${list_entries_vault_dl}" > ${pwsh_vault_cache_temp}
        search_show_entry=$(bash ${pwsh_vault_cache_temp})
        if [ -z "${search_show_entry}" ] ; then
          echo > /dev/null
        else
          echo > /dev/null | dialog --title "# pwsh-vault-dl ${VERSION} $(generate_spaces 20)" \
          --progressbox "# Decrypting Entry Number ${search_show_entry} \\" 0 0
          expr ${search_show_entry} + 1 &> /dev/null
          error=$?
          if [ ${error} -eq 0 ] ; then
            result=$(cat ${pwsh_vault_cache_logins} | head -${search_show_entry} 2>/dev/null | tail -1 | cut -d "," -f 1 | cut -d "/" -f 2)
            corrupted_result=$(check_corrupted_entry_vault ${result} logins)
            if [ ${corrupted_result} -eq 0 ] ; then
              username_decrypt=$(cat logins/${result}/login | tail -1 | cut -d ";" -f 2)
              username_decrypt=$(vault_key_decrypt "${username_decrypt}")
              password_decrypt=$(cat logins/${result}/password | tail -1 | cut -d ";" -f 2)
              password_decrypt=$(vault_key_decrypt "${password_decrypt}")
              url_decrypt=$(cat logins/${result}/url | tail -1 | cut -d ";" -f 2)
              url_decrypt=$(vault_key_decrypt "${url_decrypt}")
              otp_decrypt=$(cat logins/${result}/otp | tail -1 | cut -d ";" -f 2)
              otp_decrypt=$(vault_key_decrypt "${otp_decrypt}")
              echo "" >> ${pwsh_vault_clipboard_copy}
              echo "* Name Entry: logins/${result}" >> ${pwsh_vault_clipboard_copy}
              echo "* Login: ${username_decrypt}" >> ${pwsh_vault_clipboard_copy}
              echo "* Password: ${password_decrypt}" >> ${pwsh_vault_clipboard_copy}
              echo "* URL: ${url_decrypt}" >> ${pwsh_vault_clipboard_copy}
              echo "* OTP: ${otp_decrypt}" >> ${pwsh_vault_clipboard_copy}
              echo "* Name Entry: logins/${result}" > ${pwsh_vault_cache_temp}
              echo "* Login: ${username_decrypt}" >> ${pwsh_vault_cache_temp}
              echo "* Password: ${password_decrypt}" >> ${pwsh_vault_cache_temp}
              echo "* URL: ${url_decrypt}" >> ${pwsh_vault_cache_temp}
              echo "* OTP: ${otp_decrypt}" >> ${pwsh_vault_cache_temp}
              echo "" >> ${pwsh_vault_cache_temp}
              echo "* Data has been copied to ${pwsh_vault_clipboard_copy}" >> ${pwsh_vault_cache_temp}
              dialog --title "# pwsh-vault-dl ${VERSION}" --textbox ${pwsh_vault_cache_temp} 0 0
            else
              dialog --title "# pwsh-vault-dl ${VERSION} $(generate_spaces 20)" --msgbox "# Entry logins/${result} CORRUPTED" 0 0
            fi
          fi
        fi
      fi
      rm -rf ${pwsh_vault_cache_logins}
      rm -rf ${pwsh_vault_cache_logins_otp}
      search_entries_vault
    fi
  elif [ "${search_entry}" == "b" ] ; then
    string_search=$(dialog --stdout --title "# pwsh-vault-dl ${VERSION} $(generate_spaces 40)" --inputbox "# Type a string to search:" 0 0)
    echo > /dev/null | dialog --title "# pwsh-vault-dl ${VERSION} $(generate_spaces 20)" \
    --progressbox "# Applying Search Filter To Entries \\" 0 0
    if [ -z "${string_search}" ] ; then
      rm -rf ${pwsh_vault_cache_temp}
      touch ${pwsh_vault_cache_temp}
      touch ${pwsh_vault_cache_bcard}
      cat ${pwsh_vault_cache_bcard} >> ${pwsh_vault_cache_temp}
      cat ${pwsh_vault_cache_temp} > ${pwsh_vault_cache_bcard}
      lines_read=$(cat ${pwsh_vault_cache_bcard} 2> /dev/null | wc -l)
      if [ ${lines_read} -eq 0 ] ; then
        dialog --title "# pwsh-vault-dl ${VERSION} $(generate_spaces 20)" --msgbox "# No Entries to Show" 0 0
      else
        list_entries_vault_dl="dialog --stdout --menu '# Result Vault List Entries:' 0 0 0"
        count=1
        for show in $(cat ${pwsh_vault_cache_bcard}) ; do
          list_entries_vault_dl="${list_entries_vault_dl} ${count} \"${show}\""
          count=$(expr ${count} + 1)
        done
        echo "${list_entries_vault_dl}" > ${pwsh_vault_cache_temp}
        search_show_entry=$(bash ${pwsh_vault_cache_temp})
        if [ -z "${search_show_entry}" ] ; then
          echo > /dev/null
        else
          echo > /dev/null | dialog --title "# pwsh-vault-dl ${VERSION} $(generate_spaces 20)" \
          --progressbox "# Decrypting Entry Number ${search_show_entry} \\" 0 0
          expr ${search_show_entry} + 1 &> /dev/null
          error=$?
          if [ ${error} -eq 0 ] ; then
            result=$(cat ${pwsh_vault_cache_bcard} | head -${search_show_entry} 2>/dev/null | tail -1 | cut -d "," -f 1 | cut -d "/" -f 2)
            corrupted_result=$(check_corrupted_entry_vault ${result} bcard)
            if [ ${corrupted_result} -eq 0 ] ; then
              owner_decrypt=$(cat bcard/${result}/owner | tail -1 | cut -d ";" -f 2)
              owner_decrypt=$(vault_key_decrypt "${owner_decrypt}")
              card_decrypt=$(cat bcard/${result}/card | tail -1 | cut -d ";" -f 2)
              card_decrypt=$(vault_key_decrypt "${card_decrypt}")
              expiry_decrypt=$(cat bcard/${result}/expiry | tail -1 | cut -d ";" -f 2)
              expiry_decrypt=$(vault_key_decrypt "${expiry_decrypt}")
              cvv_decrypt=$(cat bcard/${result}/cvv | tail -1 | cut -d ";" -f 2)
              cvv_decrypt=$(vault_key_decrypt "${cvv_decrypt}")
              echo "" >> ${pwsh_vault_clipboard_copy}
              echo "* Name Entry: bcard/${result}" >> ${pwsh_vault_clipboard_copy}
              echo "* Owner: ${owner_decrypt}" >> ${pwsh_vault_clipboard_copy}
              echo "* Card: ${card_decrypt}" >> ${pwsh_vault_clipboard_copy}
              echo "* Expiry: ${expiry_decrypt}" >> ${pwsh_vault_clipboard_copy}
              echo "* CVV: ${cvv_decrypt}" >> ${pwsh_vault_clipboard_copy}
              echo "* Name Entry: bcard/${result}" > ${pwsh_vault_cache_temp}
              echo "* Owner: ${owner_decrypt}" >> ${pwsh_vault_cache_temp}
              echo "* Card: ${card_decrypt}" >> ${pwsh_vault_cache_temp}
              echo "* Expiry: ${expiry_decrypt}" >> ${pwsh_vault_cache_temp}
              echo "* CVV: ${cvv_decrypt}" >> ${pwsh_vault_cache_temp}
              echo "" >> ${pwsh_vault_cache_temp}
              echo "* Data has been copied to ${pwsh_vault_clipboard_copy}" >> ${pwsh_vault_cache_temp}
              dialog --title "# pwsh-vault-dl ${VERSION}" --textbox ${pwsh_vault_cache_temp} 0 0
            else
              dialog --title "# pwsh-vault-dl ${VERSION} $(generate_spaces 20)" --msgbox "# Entry bcard/${result} CORRUPTED" 0 0
            fi
          fi
        fi
      fi
      rm -rf ${pwsh_vault_cache_bcard}
      search_entries_vault
    else
      rm -rf ${pwsh_vault_cache_temp}
      touch ${pwsh_vault_cache_temp}
      touch ${pwsh_vault_cache_bcard}
      cat ${pwsh_vault_cache_bcard} | grep -i "${string_search}" >> ${pwsh_vault_cache_temp}
      cat ${pwsh_vault_cache_temp} > ${pwsh_vault_cache_bcard}
      lines_read=$(cat ${pwsh_vault_cache_bcard} 2> /dev/null | wc -l)
      if [ ${lines_read} -eq 0 ] ; then
        dialog --title "# pwsh-vault-dl ${VERSION} $(generate_spaces 20)" --msgbox "# No Entries to Show" 0 0
      else
        list_entries_vault_dl="dialog --stdout --menu '# Result Vault List Entries:' 0 0 0"
        count=1
        for show in $(cat ${pwsh_vault_cache_bcard}) ; do
          list_entries_vault_dl="${list_entries_vault_dl} ${count} \"${show}\""
          count=$(expr ${count} + 1)
        done
        echo "${list_entries_vault_dl}" > ${pwsh_vault_cache_temp}
        search_show_entry=$(bash ${pwsh_vault_cache_temp})
        if [ -z "${search_show_entry}" ] ; then
          echo > /dev/null
        else
          echo > /dev/null | dialog --title "# pwsh-vault-dl ${VERSION} $(generate_spaces 20)" \
          --progressbox "# Decrypting Entry Number ${search_show_entry} \\" 0 0
          expr ${search_show_entry} + 1 &> /dev/null
          error=$?
          if [ ${error} -eq 0 ] ; then
            result=$(cat ${pwsh_vault_cache_bcard} | head -${search_show_entry} 2>/dev/null | tail -1 | cut -d "," -f 1 | cut -d "/" -f 2)
            corrupted_result=$(check_corrupted_entry_vault ${result} bcard)
            if [ ${corrupted_result} -eq 0 ] ; then
              owner_decrypt=$(cat bcard/${result}/owner | tail -1 | cut -d ";" -f 2)
              owner_decrypt=$(vault_key_decrypt "${owner_decrypt}")
              card_decrypt=$(cat bcard/${result}/card | tail -1 | cut -d ";" -f 2)
              card_decrypt=$(vault_key_decrypt "${card_decrypt}")
              expiry_decrypt=$(cat bcard/${result}/expiry | tail -1 | cut -d ";" -f 2)
              expiry_decrypt=$(vault_key_decrypt "${expiry_decrypt}")
              cvv_decrypt=$(cat bcard/${result}/cvv | tail -1 | cut -d ";" -f 2)
              cvv_decrypt=$(vault_key_decrypt "${cvv_decrypt}")
              echo "" >> ${pwsh_vault_clipboard_copy}
              echo "* Name Entry: bcard/${result}" >> ${pwsh_vault_clipboard_copy}
              echo "* Owner: ${owner_decrypt}" >> ${pwsh_vault_clipboard_copy}
              echo "* Card: ${card_decrypt}" >> ${pwsh_vault_clipboard_copy}
              echo "* Expiry: ${expiry_decrypt}" >> ${pwsh_vault_clipboard_copy}
              echo "* CVV: ${cvv_decrypt}" >> ${pwsh_vault_clipboard_copy}
              echo "* Name Entry: bcard/${result}" > ${pwsh_vault_cache_temp}
              echo "* Owner: ${owner_decrypt}" >> ${pwsh_vault_cache_temp}
              echo "* Card: ${card_decrypt}" >> ${pwsh_vault_cache_temp}
              echo "* Expiry: ${expiry_decrypt}" >> ${pwsh_vault_cache_temp}
              echo "* CVV: ${cvv_decrypt}" >> ${pwsh_vault_cache_temp}
              echo "" >> ${pwsh_vault_cache_temp}
              echo "* Data has been copied to ${pwsh_vault_clipboard_copy}" >> ${pwsh_vault_cache_temp}
              dialog --title "# pwsh-vault-dl ${VERSION}" --textbox ${pwsh_vault_cache_temp} 0 0
            else
              dialog --title "# pwsh-vault-dl ${VERSION} $(generate_spaces 20)" --msgbox "# Entry bcard/${result} CORRUPTED" 0 0
            fi
          fi
        fi
      fi
      rm -rf ${pwsh_vault_cache_bcard}
      search_entries_vault
    fi
  elif [ "${search_entry}" == "n" ] ; then
    string_search=$(dialog --stdout --title "# pwsh-vault-dl ${VERSION} $(generate_spaces 40)" --inputbox "# Type a string to search:" 0 0)
    echo > /dev/null | dialog --title "# pwsh-vault-dl ${VERSION} $(generate_spaces 20)" \
    --progressbox "# Applying Search Filter To Entries \\" 0 0
    if [ -z "${string_search}" ] ; then
      rm -rf ${pwsh_vault_cache_temp}
      touch ${pwsh_vault_cache_temp}
      touch ${pwsh_vault_cache_notes}
      cat ${pwsh_vault_cache_notes} >> ${pwsh_vault_cache_temp}
      cat ${pwsh_vault_cache_temp} > ${pwsh_vault_cache_notes}
      lines_read=$(cat ${pwsh_vault_cache_notes} 2> /dev/null | wc -l)
      if [ ${lines_read} -eq 0 ] ; then
        dialog --title "# pwsh-vault-dl ${VERSION} $(generate_spaces 20)" --msgbox "# No Entries to Show" 0 0
      else
        list_entries_vault_dl="dialog --stdout --menu '# Result Vault List Entries:' 0 0 0"
        count=1
        for show in $(cat ${pwsh_vault_cache_notes}) ; do
          list_entries_vault_dl="${list_entries_vault_dl} ${count} \"${show}\""
          count=$(expr ${count} + 1)
        done
        echo "${list_entries_vault_dl}" > ${pwsh_vault_cache_temp}
        search_show_entry=$(bash ${pwsh_vault_cache_temp})
        if [ -z "${search_show_entry}" ] ; then
          echo > /dev/null
        else
          echo > /dev/null | dialog --title "# pwsh-vault-dl ${VERSION} $(generate_spaces 20)" \
          --progressbox "# Decrypting Entry Number ${search_show_entry} \\" 0 0
          expr ${search_show_entry} + 1 &> /dev/null
          error=$?
          if [ ${error} -eq 0 ] ; then
            result=$(cat ${pwsh_vault_cache_notes} | head -${search_show_entry} 2>/dev/null | tail -1 | cut -d "," -f 1 | cut -d "/" -f 2)
            corrupted_result=$(check_corrupted_entry_vault ${result} notes)
            if [ ${corrupted_result} -eq 0 ] ; then
              note_decrypt=$(cat notes/${result}/note | tail -1 | cut -d ";" -f 2)
              note_decrypt=$(vault_key_decrypt "${note_decrypt}")
              note_decrypt=$(restoreSpaces "${note_decrypt}")
              echo "" >> ${pwsh_vault_clipboard_copy}
              echo "* Name Entry: notes/${result}" >> ${pwsh_vault_clipboard_copy}
              echo "* Note: ${note_decrypt}" >> ${pwsh_vault_clipboard_copy}
              echo "* Name Entry: notes/${result}" > ${pwsh_vault_cache_temp}
              echo "* Note: ${note_decrypt}" >> ${pwsh_vault_cache_temp}
              echo "" >> ${pwsh_vault_cache_temp}
              echo "* Data has been copied to ${pwsh_vault_clipboard_copy}" >> ${pwsh_vault_cache_temp}
              dialog --title "# pwsh-vault-dl ${VERSION}" --textbox ${pwsh_vault_cache_temp} 0 0
            else
              dialog --title "# pwsh-vault-dl ${VERSION} $(generate_spaces 20)" --msgbox "# Entry notes/${result} CORRUPTED" 0 0
            fi
          fi
        fi
      fi
      rm -rf ${pwsh_vault_cache_notes}
      search_entries_vault
    else
      rm -rf ${pwsh_vault_cache_temp}
      touch ${pwsh_vault_cache_temp}
      touch ${pwsh_vault_cache_notes}
      cat ${pwsh_vault_cache_notes} | grep -i "${string_search}" >> ${pwsh_vault_cache_temp}
      cat ${pwsh_vault_cache_temp} > ${pwsh_vault_cache_notes}
      lines_read=$(cat ${pwsh_vault_cache_notes} 2> /dev/null | wc -l)
      if [ ${lines_read} -eq 0 ] ; then
        dialog --title "# pwsh-vault-dl ${VERSION} $(generate_spaces 20)" --msgbox "# No Entries to Show" 0 0
      else
        list_entries_vault_dl="dialog --stdout --menu '# Result Vault List Entries:' 0 0 0"
        count=1
        for show in $(cat ${pwsh_vault_cache_notes}) ; do
          list_entries_vault_dl="${list_entries_vault_dl} ${count} \"${show}\""
          count=$(expr ${count} + 1)
        done
        echo "${list_entries_vault_dl}" > ${pwsh_vault_cache_temp}
        search_show_entry=$(bash ${pwsh_vault_cache_temp})
        if [ -z "${search_show_entry}" ] ; then
          echo > /dev/null
        else
          echo > /dev/null | dialog --title "# pwsh-vault-dl ${VERSION} $(generate_spaces 20)" \
          --progressbox "# Decrypting Entry Number ${search_show_entry} \\" 0 0
          expr ${search_show_entry} + 1 &> /dev/null
          error=$?
          if [ ${error} -eq 0 ] ; then
            result=$(cat ${pwsh_vault_cache_notes} | head -${search_show_entry} 2>/dev/null | tail -1 | cut -d "," -f 1 | cut -d "/" -f 2)
            corrupted_result=$(check_corrupted_entry_vault ${result} notes)
            if [ ${corrupted_result} -eq 0 ] ; then
              note_decrypt=$(cat notes/${result}/note | tail -1 | cut -d ";" -f 2)
              note_decrypt=$(vault_key_decrypt "${note_decrypt}")
              note_decrypt=$(restoreSpaces "${note_decrypt}")
              echo "" >> ${pwsh_vault_clipboard_copy}
              echo "* Name Entry: notes/${result}" >> ${pwsh_vault_clipboard_copy}
              echo "* Note: ${note_decrypt}" >> ${pwsh_vault_clipboard_copy}
              echo "* Name Entry: notes/${result}" > ${pwsh_vault_cache_temp}
              echo "* Note: ${note_decrypt}" >> ${pwsh_vault_cache_temp}
              echo "" >> ${pwsh_vault_cache_temp}
              echo "* Data has been copied to ${pwsh_vault_clipboard_copy}" >> ${pwsh_vault_cache_temp}
              dialog --title "# pwsh-vault-dl ${VERSION}" --textbox ${pwsh_vault_cache_temp} 0 0
            else
              dialog --title "# pwsh-vault-dl ${VERSION} $(generate_spaces 20)" --msgbox "# Entry notes/${result} CORRUPTED" 0 0
            fi
          fi
        fi
      fi
      rm -rf ${pwsh_vault_cache_notes}
      search_entries_vault
    fi
  else
    echo > /dev/null
  fi
}

function reset_config() {
  echo "# All settings will be deleted"
  echo -n "# Do you want to continue (Default: n) (y/n): " ; read reset
  if [ "${reset}" == "y" ] ; then
    rm -rfv ${pwsh_vault}/*
    echo "# All settings have been deleted"
  fi
}

function pwsh_vault_main() {
  vault_main_init=0
  while [ ${vault_main_init} -eq 0 ] ;do
    vault_main_option=$(dialog --stdout --menu "# pwsh-vault-dl ${VERSION}" \
    0 0 0 c "Create Entry" e "Edit Entry" s "Search Entry" l "List Entry" \
    r "Remove Entry" m "Change MasterKey" g "Generate Password" x "Export Vault" \
    i "Import Vault" a "About" q "Quit")
    if [ "${vault_main_option}" == "c" ] ; then
      create_entries_menu
    elif [ "${vault_main_option}" == "e" ] ; then
      edit_entry_vault
    elif [ "${vault_main_option}" == "s" ] ; then
      search_entries_vault
    elif [ "${vault_main_option}" == "l" ] ; then
      list_entries_vault
    elif [ "${vault_main_option}" == "r" ] ; then
      remove_entry_vault
    elif [ "${vault_main_option}" == "a" ] ; then
      pwsh_vault_about
    elif [ "${vault_main_option}" == "m" ] ; then
      change_masterkey_vault
    elif [ "${vault_main_option}" == "g" ] ; then
      generate_password_menu
    elif [ "${vault_main_option}" == "x" ] ; then
      export_pwsh_vault
    elif [ "${vault_main_option}" == "i" ] ; then
      import_pwsh_vault
    elif [ "${vault_main_option}" == "q" ] ; then
      vault_main_init=1
      exit
    else
      echo > /dev/null
    fi
  done
}

function check_dialog() {
  dialog --help &> /dev/null
  error=$?
  if [ ${error} -ne 0 ] ; then
    pwsh-vault-cli
    exit
  fi
}

# Create directories & run script
mkdir -p ${pwsh_vault}
mkdir -p ${pwsh_vault}/notes
mkdir -p ${pwsh_vault}/logins
mkdir -p ${pwsh_vault}/bcard
mkdir -p ${HOME}/.cache
touch ${pwsh_vault_cache_logins}
touch ${pwsh_vault_cache_notes}
touch ${pwsh_vault_cache_bcard}
touch ${pwsh_vault_cache_temp}
rm -rf ${pwsh_vault_clipboard_copy}
check_dialog
if [ "${1}" == "--help" ] ; then
  pwsh_vault_help
elif [ "${1}" == "-h" ] ; then
  pwsh_vault_help
elif [ "${1}" == "--export" ] ; then
  if [ "${2}" == "--encrypt" ] ; then
    export_pwsh_vault_param_encrypt
  else
    export_pwsh_vault_param
  fi
elif [ "${1}" == "--import" ] ; then
  import_pwsh_vault_param "${2}"
elif [ "${1}" == "--reset" ] ; then
  reset_config
elif [ "${1}" == "--gen-password" ] ; then
  if [ -z "${2}" ] ; then
    generate_password "20" "param"
  else
    generate_password "${2}" "param"
  fi
else
  init_masterkey
  pwsh_vault_main
fi

