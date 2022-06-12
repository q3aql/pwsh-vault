#!/bin/bash

###########################################################
# pwsh-vault - Password Manager written with Bash (Dmenu) #
# Author: q3aql                                           #
# Contact: q3aql@duck.com                                 #
# License: GPL v2.0                                       #
# Last-Change: 12-06-20222                                #
# #########################################################
VERSION="0.1"

# Variables
pwsh_vault="${HOME}/.pwsh-vault"
pwsh_vault_masterkey="${pwsh_vault}/masterkey"
pwsh_vault_cache_logins="${HOME}/.cache/pwsh_vault_cache_logins"
pwsh_vault_cache_logins_otp="${HOME}/.cache/pwsh_vault_cache_logins_otp"
pwsh_vault_cache_notes="${HOME}/.cache/pwsh_vault_cache_notes"
pwsh_vault_cache_bcard="${HOME}/.cache/pwsh_vault_cache_bcard"
pwsh_vault_cache_temp="${HOME}/.cache/pwsh_vault_cache_temp"
file_code_sec="/tmp/pwsh-vault-seq"
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

show_icon_tree() {
  ls -1 | while read current ; do
    if [ -f "${current}" ] ; then
      echo "  ${current}"
    elif [ -d "${current}" ] ; then
      echo "  ${current}"
    else
      echo "  ${current}"
    fi
  done
}

remove_icon() {
  entry="${@}"
  remove_icon_space=0
  read_entry=$(echo "${entry}" | grep "  ")
  if ! [ -z "${read_entry}" ] ; then
    remove_icon_space=1
  fi
  read_entry=$(echo "${entry}" | grep "  ")
  if ! [ -z "${read_entry}" ] ; then
    remove_icon_space=1
  fi
  read_entry=$(echo "${entry}" | grep "  ")
  if ! [ -z "${read_entry}" ] ; then
    remove_icon_space=1
  fi
  if [ ${remove_icon_space} -eq 1 ] ; then
    show_output=$(echo "${entry}" | cut -c4-999 | tr -s " " | cut -c2-999)
    echo "${show_output}"
  else
   echo "${entry}"
  fi 
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
  elif [ ${1} -lt 8 ] ; then
    default_long_password=10
  else
    default_long_password=${1}
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

function generate_password_gui() {
  if [ -z "${1}" ] ; then
    default_long_password=20
  elif [ ${1} -lt 8 ] ; then
    default_long_password=10
  elif [ ${1} -gt 30 ] ; then
    default_long_password=30
  else
    default_long_password=${1}
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
  echo ${current_password} >> ${pwsh_vault_password_copy}
  echo > /dev/null | pwsh-vaultm -p "  PASSWORD: ${current_password} $(generate_spaces 65)"
  echo > /dev/null | pwsh-vaultm -p "  Password has been copied to ${pwsh_vault_password_copy} $(generate_spaces 20)"
}

function generate_password_menu() {
  size_password=$(echo > /dev/null | pwsh-vaultm -p "  Set the password size (Default: 20):")
  generate_password_gui "${size_password}"
}

function init_masterkey() {
  if [ -f ${pwsh_vault_masterkey} ] ; then
    read_masterkey_vault=$(echo > /dev/null | pwsh-vaultm -p "  Enter MasterKey Vault:")
    read_masterkey=$(cat ${pwsh_vault_masterkey} | cut -d ";" -f 2)
    decrypt_masterkey=$(vault_key_decrypt "${read_masterkey}")
    if [ "${decrypt_masterkey}" == "${read_masterkey_vault}" ] ; then
      echo "# MasterKey is valid"
    else
      echo > /dev/null | pwsh-vaultm -p "  Wrong MasterKey $(generate_spaces 70)"
      exit
    fi
  else
    echo > /dev/null | pwsh-vaultm -p "  A masterkey has not yet been defined $(generate_spaces 50)"
    masterkey_input=$(echo > /dev/null | pwsh-vaultm -p "  Enter New MasterKey:")
    masterkey_reinput=$(echo > /dev/null | pwsh-vaultm -p "  Re-Enter New MasterKey:")
    if [ "${masterkey_input}" == "${masterkey_reinput}" ] ; then
      echo ""
      masterkey_name=$(vault_key_encrypt "Masterkey")
      masterkey_gen=$(vault_key_encrypt "${masterkey_input}")
      echo "${masterkey_name};${masterkey_gen}" > ${pwsh_vault_masterkey}
      echo ""
      echo "# New MasterKey defined correctly"
    else
      echo > /dev/null | pwsh-vaultm -p "  Both passwords do not match $(generate_spaces 60)"
      exit
    fi
  fi
}

function create_login_vault_entry() {
  name_login_entry=0
  masterkey_load=$(cat ${pwsh_vault_masterkey})
  while [ ${name_login_entry} -eq 0 ] ; do
    name_entry=$(echo > /dev/null | pwsh-vaultm -p "爵  Enter Name for Login Entry:")
    if [ ! -z "${name_entry}" ] ; then
      name_entry=$(removeSpaces "${name_entry}")
      mkdir -p "${pwsh_vault}/logins/${name_entry}"
      name_login_entry=1
    fi
  done
  username_entry=0
  while [ ${username_entry} -eq 0 ] ; do
    name_username=$(echo > /dev/null | pwsh-vaultm -p "爵  Enter Username:")
    if [ ! -z "${name_username}" ] ; then
      name_username=$(vault_key_encrypt "${name_username}")
      username_text=$(vault_key_encrypt "Username")
      echo "${masterkey_load}" > "${pwsh_vault}/logins/${name_entry}/login"
      echo "${username_text};${name_username}" >> "${pwsh_vault}/logins/${name_entry}/login"
      username_entry=1
    fi
  done
  password_entry=0
  while [ ${password_entry} -eq 0 ] ; do
    name_password=$(echo > /dev/null | pwsh-vaultm -p "爵  Enter Password:")
    if [ ! -z "${name_password}" ] ; then
      name_password=$(vault_key_encrypt "${name_password}")
      password_text=$(vault_key_encrypt "Password")
      echo "${masterkey_load}" > "${pwsh_vault}/logins/${name_entry}/password"
      echo "${password_text};${name_password}" >> "${pwsh_vault}/logins/${name_entry}/password"
      password_entry=1
    fi
  done
  url_entry=0
  while [ ${url_entry} -eq 0 ] ; do
    name_url=$(echo > /dev/null | pwsh-vaultm -p "爵  Enter URL:")
    if [ ! -z "${name_url}" ] ; then
      name_url=$(vault_key_encrypt "${name_url}")
      url_text=$(vault_key_encrypt "URL")
      echo "${masterkey_load}" > "${pwsh_vault}/logins/${name_entry}/url"
      echo "${url_text};${name_url}" >> "${pwsh_vault}/logins/${name_entry}/url"
      url_entry=1
    fi
  done
  otp_entry=0
  while [ ${otp_entry} -eq 0 ] ; do
    name_otp=$(echo > /dev/null | pwsh-vaultm -p "爵  Enter OTP (Default: None):")
    if [ ! -z "${name_otp}" ] ; then
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
  echo > /dev/null | pwsh-vaultm -p "爵  LOGIN ENTRY CREATED: ${name_entry} $(generate_spaces 60)"
  create_entries_menu
}

function create_bcard_vault_entry() {
  name_bcard_entry=0
  masterkey_load=$(cat ${pwsh_vault_masterkey})
  while [ ${name_bcard_entry} -eq 0 ] ; do
    name_entry=$(echo > /dev/null | pwsh-vaultm -p "  Enter Name for Bcard Entry:")
    if [ ! -z "${name_entry}" ] ; then
      name_entry=$(removeSpaces "${name_entry}")
      mkdir -p "${pwsh_vault}/bcard/${name_entry}"
      name_bcard_entry=1
    fi
  done
  owner_entry=0
  while [ ${owner_entry} -eq 0 ] ; do
    name_owner=$(echo > /dev/null | pwsh-vaultm -p "  Enter Owner:")
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
    name_card=$(echo > /dev/null | pwsh-vaultm -p "  Enter Card Number (XXXX-XXXX-XXXX-XXXX):")
    if [ ! -z "${name_card}" ] ; then
      name_card=$(vault_key_encrypt "${name_card}")
      card_text=$(vault_key_encrypt "Card")
      echo "${masterkey_load}" > "${pwsh_vault}/bcard/${name_entry}/card"
      echo "${card_text};${name_card}" >> "${pwsh_vault}/bcard/${name_entry}/card"
      card_entry=1
    fi
  done
  expiry_entry=0
  while [ ${expiry_entry} -eq 0 ] ; do
    name_expiry=$(echo > /dev/null | pwsh-vaultm -p "  Enter Expiry Date (MM/YY):")
    if [ ! -z "${name_expiry}" ] ; then
      name_expiry=$(vault_key_encrypt "${name_expiry}")
      expiry_text=$(vault_key_encrypt "Expiry")
      echo "${masterkey_load}" > "${pwsh_vault}/bcard/${name_entry}/expiry"
      echo "${expiry_text};${name_expiry}" >> "${pwsh_vault}/bcard/${name_entry}/expiry"
      expiry_entry=1
    fi
  done
  cvv_entry=0
  while [ ${cvv_entry} -eq 0 ] ; do
    name_cvv=$(echo > /dev/null | pwsh-vaultm -p "  Enter CVV:")
    if [ ! -z "${name_cvv}" ] ; then
      name_cvv=$(vault_key_encrypt "${name_cvv}")
      cvv_text=$(vault_key_encrypt "CVV")
      echo "${masterkey_load}" > "${pwsh_vault}/bcard/${name_entry}/cvv"
      echo "${cvv_text};${name_cvv}" >> "${pwsh_vault}/bcard/${name_entry}/cvv"
      cvv_entry=1
    fi
  done
  echo > /dev/null | pwsh-vaultm -p "  CARD ENTRY CREATED: ${name_entry} $(generate_spaces 60)"
  create_entries_menu
}

function create_note_vault_entry() {
  name_note_entry=0
  masterkey_load=$(cat ${pwsh_vault_masterkey})
  while [ ${name_note_entry} -eq 0 ] ; do
    name_entry=$(echo > /dev/null | pwsh-vaultm -p "  Enter Name for Note Entry:")
    if [ ! -z "${name_entry}" ] ; then
      name_entry=$(removeSpaces "${name_entry}")
      mkdir -p "${pwsh_vault}/notes/${name_entry}"
      name_note_entry=1
    fi
  done
  note_entry=0
  while [ ${note_entry} -eq 0 ] ; do
    name_note=$(echo > /dev/null | pwsh-vaultm -p "  Enter Note:")
    if [ ! -z "${name_note}" ] ; then
      name_note=$(removeSpaces "${name_note}")
      name_note=$(vault_key_encrypt "${name_note}")
      note_text=$(vault_key_encrypt "Note")
      echo "${masterkey_load}" > "${pwsh_vault}/notes/${name_entry}/note"
      echo "${note_text};${name_note}" >> "${pwsh_vault}/notes/${name_entry}/note"
      note_entry=1
    fi
  done
  echo > /dev/null | pwsh-vaultm -p "  NOTE ENTRY CREATED: ${name_entry} $(generate_spaces 60)"
  create_entries_menu
}

function create_entries_menu_show() {
  echo "爵  Login/Website Entry"
  echo "  Credit/Bank Card Entry"
  echo "  Note Entry"
}

function create_entries_menu() {
  new_entry=$(create_entries_menu_show | pwsh-vaultm -p "  New Entry:")
  if [ "${new_entry}" == "爵  Login/Website Entry" ] ; then
    create_login_vault_entry
  elif [ "${new_entry}" == "  Credit/Bank Card Entry" ] ; then
    create_bcard_vault_entry
  elif [ "${new_entry}" == "  Note Entry" ] ; then
    create_note_vault_entry
  else
      echo > /dev/null
  fi
}

function list_folders_pwsh_vault() {
  cd ${pwsh_vault}
  count_logins=$(ls -1 logins/ | wc -l)
  count_bcard=$(ls -1 bcard/ | wc -l)
  count_notes=$(ls -1 notes/ | wc -l)
  if [ ${count_logins} -ne 0 ] ; then
    for show in $(ls -1 logins/) ; do
      echo "爵  logins/${show}"
    done
  fi
  if [ ${count_bcard} -ne 0 ] ; then
    for show in $(ls -1 bcard/) ; do
      echo "  bcard/${show}"
    done
  fi
  if [ ${count_notes} -ne 0 ] ; then
    for show in $(ls -1 notes/) ; do
      echo "  notes/${show}"
    done
  fi
}

function export_pwsh_vault() {
  name_date=$(date +%Y-%m-%d_%H%M)
  cd ${pwsh_vault}
  export_vault=$(echo -e "No\nYes" | pwsh-vaultm -p "  Set Password When Exporting?:")
  if [ "${export_vault}" == "Yes" ] ; then
    password_export=$(echo > /dev/null | pwsh-vaultm -p "  Enter Exporting Password:")
    repassword_export=$(echo > /dev/null | pwsh-vaultm -p "  Re-Enter Exporting Password:")
    if [ "${password_export}" == "${repassword_export}" ] ; then
      zip -P "${password_export}" -r ${HOME}/pwsh-vault-export_${name_date}.zip *
      error=$?
      if [ ${error} -eq 0 ] ; then
        echo > /dev/null | pwsh-vaultm -p "  Vault exported to ${HOME}/pwsh-vault-export_${name_date}.zip $(generate_spaces 20)"
      else
        echo > /dev/null | pwsh-vaultm -p "  Error Exporting Vault $(generate_spaces 65)"
        rm -rf ${HOME}/pwsh-vault-export_${name_date}.zip
      fi
    else
      echo > /dev/null | pwsh-vaultm -p "  Both passwords do not match $(generate_spaces 60)"
    fi
  else
    zip -r ${HOME}/pwsh-vault-export_${name_date}.zip *
    error=$?
    if [ ${error} -eq 0 ] ; then
      echo > /dev/null | pwsh-vaultm -p "  Vault exported to ${HOME}/pwsh-vault-export_${name_date}.zip $(generate_spaces 20)"
    else
      echo > /dev/null | pwsh-vaultm -p "  Error Exporting Vault $(generate_spaces 65)"
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
  file=1
  while [ "${file}" ] ; do
    #file=$(ls -1 | pwsh-vaultm -p "  Import: $(basename $(pwd))")
    file=$(show_icon_tree | pwsh-vaultm -p "  Import: $(basename $(pwd))")
    file=$(remove_icon "${file}")
    echo "# ${file} #"
    if [ -e "${file}" ] ; then
      owd=$(pwd)
      if [ -d "${file}" ] ; then
        cd "${file}"
      else [ -f "${file}" ] 
        password_import=$(echo > /dev/null | pwsh-vaultm -p "  Enter Importing Password (Blank if Does Not Have):")
        if [ -z "${password_import}" ] ; then
          password_import="test"
        fi
        unzip -P "${password_import}" -o "${owd}/${file}" -d ${pwsh_vault}
        error=$?
        if [ ${error} -eq 0 ] ; then
          echo > /dev/null | pwsh-vaultm -p "  Vault imported from ${owd}/${file} $(generate_spaces 20)"
        else
          echo > /dev/null | pwsh-vaultm -p "  Error Importing Vault $(generate_spaces 65)"
        fi
        unset file
      fi
    fi
  done
}

function import_pwsh_vault_param() {
  cd ${pwsh_vault}
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

function pwsh_vault_show_about() {
  echo "  Software: pwsh-vault ${VERSION}"
  echo "  Contact: q3aql <q3aql@duck.com>"
  echo "  LICENSE: GPLv2.0"
}

function pwsh_vault_about() {
  pwsh_vault_show_about | pwsh-vaultm -p "  About:"
}

function pwsh_vault_help() {
    echo ""
    echo "# pwsh-vault ${VERSION}"
    echo ""
    echo "# Usage:"
    echo "  $ pwsh-vault                      --> Run Main GUI"
    echo "  $ pwsh-vault --export [--encrypt] --> Export Vault"
    echo "  $ pwsh-vault --import <path-file> --> Import Vault"
    echo "  $ pwsh-vault --gen-password [num] --> Generate password"
    echo "  $ pwsh-vault --help               --> Show Help"
    echo ""
    exit
}

function process_extracted_vault_logins() {
  vault_cache_length=$(cat ${pwsh_vault_cache_logins} | wc -l)
  count_length=1
  # Count the width of all cells
  name_length=9
  login_length=5
  password_length=8
  url_length=3
  otp_length=3
  while [ ${count_length} -le ${vault_cache_length} ] ; do
    name_count=$(cat ${pwsh_vault_cache_logins} | head -${count_length} | tail -1 | cut -d "," -f 1 | wc -m)
    login_count=$(cat ${pwsh_vault_cache_logins} | head -${count_length} | tail -1 | cut -d "," -f 2 | wc -m)
    password_count=$(cat ${pwsh_vault_cache_logins} | head -${count_length} | tail -1 | cut -d "," -f 3 | wc -m)
    url_count=$(cat ${pwsh_vault_cache_logins} | head -${count_length} | tail -1 | cut -d "," -f 4 | wc -m)
    otp_count=$(cat ${pwsh_vault_cache_logins} | head -${count_length} | tail -1 | cut -d "," -f 5 | wc -m)
    # Compare the maximum size of the variables
    if [ ${name_count} -gt ${name_length} ] ; then
      name_length=${name_count}
    fi
    if [ ${login_count} -gt ${login_length} ] ; then
      login_length=${login_count}
    fi
    if [ ${password_count} -gt ${password_length} ] ; then
      password_length=${password_count}
    fi
    if [ ${url_count} -gt ${url_length} ] ; then
      url_length=${url_count}
    fi
    if [ ${otp_count} -gt ${otp_length} ] ; then
      otp_length=${otp_count}
    fi
    count_length=$(expr ${count_length} + 1)
  done
  count_length=1
  row_length=$(expr ${name_length} + ${login_length} + ${password_length} + ${url_length} + ${otp_length} + 23)
  row_length_show=1
  # Display data in rows
  count_length=1
  show_bar=0
  while [ ${count_length} -le ${vault_cache_length} ] ; do
    # Read the value
    name=$(cat ${pwsh_vault_cache_logins} | head -${count_length} | tail -1 | cut -d "," -f 1)
    login=$(cat ${pwsh_vault_cache_logins} | head -${count_length} | tail -1 | cut -d "," -f 2)
    password=$(cat ${pwsh_vault_cache_logins} | head -${count_length} | tail -1 | cut -d "," -f 3)
    url=$(cat ${pwsh_vault_cache_logins} | head -${count_length} | tail -1 | cut -d "," -f 4)
    otp=$(cat ${pwsh_vault_cache_logins} | head -${count_length} | tail -1 | cut -d "," -f 5)
    # Counting the letters
    name_count=$(cat ${pwsh_vault_cache_logins} | head -${count_length} | tail -1 | cut -d "," -f 1 | wc -m)
    login_count=$(cat ${pwsh_vault_cache_logins} | head -${count_length} | tail -1 | cut -d "," -f 2 | wc -m)
    password_count=$(cat ${pwsh_vault_cache_logins} | head -${count_length} | tail -1 | cut -d "," -f 3 | wc -m)
    url_count=$(cat ${pwsh_vault_cache_logins} | head -${count_length} | tail -1 | cut -d "," -f 4 | wc -m)
    otp_count=$(cat ${pwsh_vault_cache_logins} | head -${count_length} | tail -1 | cut -d "," -f 5 | wc -m)
    # Calculate the spaces in each row separately
    name_count=$(expr ${name_length} - ${name_count})
    login_count=$(expr ${login_length} - ${login_count})
    password_count=$(expr ${password_length} - ${password_count})
    url_count=$(expr ${url_length} - ${url_count})
    otp_count=$(expr ${otp_length} - ${otp_count})
    # Show each row separately
    echo -n "  ${name}"
    name_max=1
    while [ ${name_max} -le ${name_count} ] ; do
      echo -n " "
      name_max=$(expr ${name_max} + 1)
    done
    echo -n " - "
    echo -n "﫻  ${login}"
    login_max=1
    while [ ${login_max} -le ${login_count} ] ; do
      echo -n " "
      login_max=$(expr ${login_max} + 1)
    done
    echo -n " - "
    echo -n "  ${password}"
    password_max=1
    while [ ${password_max} -le ${password_count} ] ; do
      echo -n " "
      password_max=$(expr ${password_max} + 1)
    done
    echo -n " - "
    echo -n "爵  ${url}"
    url_max=1
    while [ ${url_max} -le ${url_count} ] ; do
      echo -n " "
      url_max=$(expr ${url_max} + 1)
    done
    echo -n " - "
    echo -n "勒  ${otp}"
    otp_max=1
    while [ ${otp_max} -le ${otp_count} ] ; do
      echo -n " "
      otp_max=$(expr ${otp_max} + 1)
    done
    echo ""
    count_length=$(expr ${count_length} + 1)
    if [ ${show_bar} -eq 0 ] ; then
      row_length=$(expr ${name_length} + ${login_length} + ${password_length} + ${url_length} + ${otp_length} + 23)
      row_length_show=1
      show_bar=1
    fi
  done
  echo ""
}

function process_extracted_vault_bcard() {
  vault_cache_length=$(cat ${pwsh_vault_cache_bcard} | wc -l)
  count_length=1
  # Count the width of all cells
  name_length=9
  owner_length=5
  card_length=8
  expiry_length=3
  cvv_length=3
  while [ ${count_length} -le ${vault_cache_length} ] ; do
    name_count=$(cat ${pwsh_vault_cache_bcard} | head -${count_length} | tail -1 | cut -d "," -f 1 | wc -m)
    owner_count=$(cat ${pwsh_vault_cache_bcard} | head -${count_length} | tail -1 | cut -d "," -f 2 | wc -m)
    card_count=$(cat ${pwsh_vault_cache_bcard} | head -${count_length} | tail -1 | cut -d "," -f 3 | wc -m)
    expiry_count=$(cat ${pwsh_vault_cache_bcard} | head -${count_length} | tail -1 | cut -d "," -f 4 | wc -m)
    cvv_count=$(cat ${pwsh_vault_cache_bcard} | head -${count_length} | tail -1 | cut -d "," -f 5 | wc -m)
    # Compare the maximum size of the variables
    if [ ${name_count} -gt ${name_length} ] ; then
      name_length=${name_count}
    fi
    if [ ${owner_count} -gt ${owner_length} ] ; then
      owner_length=${owner_count}
    fi
    if [ ${card_count} -gt ${card_length} ] ; then
      card_length=${card_count}
    fi
    if [ ${expiry_count} -gt ${expiry_length} ] ; then
      expiry_length=${expiry_count}
    fi
    if [ ${cvv_count} -gt ${cvv_length} ] ; then
      cvv_length=${cvv_count}
    fi
    count_length=$(expr ${count_length} + 1)
  done
  count_length=1
  row_length=$(expr ${name_length} + ${owner_length} + ${card_length} + ${expiry_length} + ${cvv_length} + 23)
  row_length_show=1
  # Display data in rows
  count_length=1
  show_bar=0
  while [ ${count_length} -le ${vault_cache_length} ] ; do
    # Read the value
    name=$(cat ${pwsh_vault_cache_bcard} | head -${count_length} | tail -1 | cut -d "," -f 1)
    owner=$(cat ${pwsh_vault_cache_bcard} | head -${count_length} | tail -1 | cut -d "," -f 2)
    card=$(cat ${pwsh_vault_cache_bcard} | head -${count_length} | tail -1 | cut -d "," -f 3)
    expiry=$(cat ${pwsh_vault_cache_bcard} | head -${count_length} | tail -1 | cut -d "," -f 4)
    cvv=$(cat ${pwsh_vault_cache_bcard} | head -${count_length} | tail -1 | cut -d "," -f 5)
    # Counting the letters
    name_count=$(cat ${pwsh_vault_cache_bcard} | head -${count_length} | tail -1 | cut -d "," -f 1 | wc -m)
    owner_count=$(cat ${pwsh_vault_cache_bcard} | head -${count_length} | tail -1 | cut -d "," -f 2 | wc -m)
    card_count=$(cat ${pwsh_vault_cache_bcard} | head -${count_length} | tail -1 | cut -d "," -f 3 | wc -m)
    expiry_count=$(cat ${pwsh_vault_cache_bcard} | head -${count_length} | tail -1 | cut -d "," -f 4 | wc -m)
    cvv_count=$(cat ${pwsh_vault_cache_bcard} | head -${count_length} | tail -1 | cut -d "," -f 5 | wc -m)
    # Calculate the spaces in each row separately
    name_count=$(expr ${name_length} - ${name_count})
    owner_count=$(expr ${owner_length} - ${owner_count})
    card_count=$(expr ${card_length} - ${card_count})
    expiry_count=$(expr ${expiry_length} - ${expiry_count})
    cvv_count=$(expr ${cvv_length} - ${cvv_count})
    # Show each row separately
    echo -n "  ${name}"
    name_max=1
    while [ ${name_max} -le ${name_count} ] ; do
      echo -n " "
      name_max=$(expr ${name_max} + 1)
    done
    echo -n " - "
    echo -n "  ${owner}"
    owner_max=1
    while [ ${owner_max} -le ${owner_count} ] ; do
      echo -n " "
      owner_max=$(expr ${owner_max} + 1)
    done
    echo -n " - "
    echo -n "  ${card}"
    card_max=1
    while [ ${card_max} -le ${card_count} ] ; do
      echo -n " "
      card_max=$(expr ${card_max} + 1)
    done
    echo -n " - "
    echo -n "  ${expiry}"
    expiry_max=1
    while [ ${expiry_max} -le ${expiry_count} ] ; do
      echo -n " "
      expiry_max=$(expr ${expiry_max} + 1)
    done
    echo -n " - "
    echo -n "况  ${cvv}"
    cvv_max=1
    while [ ${cvv_max} -le ${cvv_count} ] ; do
      echo -n " "
      cvv_max=$(expr ${cvv_max} + 1)
    done
    echo ""
    count_length=$(expr ${count_length} + 1)
    if [ ${show_bar} -eq 0 ] ; then
      row_length=$(expr ${name_length} + ${owner_length} + ${card_length} + ${expiry_length} + ${cvv_length} + 23)
      row_length_show=1
      show_bar=1
    fi
  done
  echo ""
}

function process_extracted_vault_notes() {
  vault_cache_length=$(cat ${pwsh_vault_cache_notes} | wc -l)
  count_length=1
  # Count the width of all cells
  name_length=9
  note_length=5
  while [ ${count_length} -le ${vault_cache_length} ] ; do
    name_count=$(cat ${pwsh_vault_cache_notes} | head -${count_length} | tail -1 | cut -d "," -f 1 | wc -m)
    note_count=$(cat ${pwsh_vault_cache_notes} | head -${count_length} | tail -1 | cut -d "," -f 2 | wc -m)
    if [ ${name_count} -gt ${name_length} ] ; then
      name_length=${name_count}
    fi
    if [ ${note_count} -gt ${note_length} ] ; then
      note_length=${note_count}
    fi
    count_length=$(expr ${count_length} + 1)
  done
  count_length=1
  row_length=$(expr ${name_length} + ${note_length} + 9)
  row_length_show=1
  # Display data in rows
  count_length=1
  show_bar=0
  while [ ${count_length} -le ${vault_cache_length} ] ; do
    # Read the value
    name=$(cat ${pwsh_vault_cache_notes} | head -${count_length} | tail -1 | cut -d "," -f 1)
    note=$(cat ${pwsh_vault_cache_notes} | head -${count_length} | tail -1 | cut -d "," -f 2)
    # Counting the letters
    name_count=$(cat ${pwsh_vault_cache_notes} | head -${count_length} | tail -1 | cut -d "," -f 1 | wc -m)
    note_count=$(cat ${pwsh_vault_cache_notes} | head -${count_length} | tail -1 | cut -d "," -f 2 | wc -m)
    # Calculate the spaces in each row separately
    name_count=$(expr ${name_length} - ${name_count})
    note_count=$(expr ${note_length} - ${note_count})
    # Show each row separately
    echo -n "  ${name}"
    name_max=1
    while [ ${name_max} -le ${name_count} ] ; do
      echo -n " "
      name_max=$(expr ${name_max} + 1)
    done
    echo -n " - "
    echo -n "  ${note}"
    note_max=1
    while [ ${note_max} -le ${note_count} ] ; do
      echo -n " "
      note_max=$(expr ${note_max} + 1)
    done
    echo ""
    count_length=$(expr ${count_length} + 1)
    if [ ${show_bar} -eq 0 ] ; then
      row_length=$(expr ${name_length} + ${note_length} + 9)
      row_length_show=1
      show_bar=1
    fi
  done
  echo ""
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

function run_all_list_process_extracted_vault() {
  list_logins_count=$(ls -1 logins/ | wc -l)
  list_bcard_count=$(ls -1 bcard/ | wc -l)
  list_notes_count=$(ls -1 notes/ | wc -l)
  if [ ${list_logins_count} -ne 0 ] ; then
    process_extracted_vault_logins
  fi
  if [ ${list_bcard_count} -ne 0 ] ; then
    process_extracted_vault_bcard
  fi
  if [ ${list_notes_count} -ne 0 ] ; then
    process_extracted_vault_notes
  fi
  rm -rf ${pwsh_vault_cache_logins}
  rm -rf ${pwsh_vault_cache_bcard}
  rm -rf ${pwsh_vault_cache_notes}
}

function list_entries_vault() {
  clear
  cd ${pwsh_vault}
  echo ""
  echo "# pwsh-vault ${VERSION}"
  echo ""
  echo "# Creating Vault List Entries"
  echo ""
  touch ${pwsh_vault_cache_logins}
  touch ${pwsh_vault_cache_bcard}
  touch ${pwsh_vault_cache_notes}
  list_logins_count=$(ls -1 logins/ | wc -l)
  list_bcard_count=$(ls -1 bcard/ | wc -l)
  list_notes_count=$(ls -1 notes/ | wc -l)
  if [ ${list_logins_count} -ne 0 ] ; then
    list_logins=$(ls -1 logins/)
    username_show="Hidden User"
    password_show="Encrypted Password"
    url_show="Hidden URL"
    otp_show="Hidden OTP"
    for login in ${list_logins} ; do
      echo "logins/${login},${username_show},${password_show},${url_show},${otp_show}" >> ${pwsh_vault_cache_logins}
    done
  fi
  cd ${pwsh_vault}
  if [ ${list_bcard_count} -ne 0 ] ; then
    list_bcard=$(ls -1 bcard/)
    owner_show="Hidden Owner"
    num_card_show="Hidden Card"
    expiry_show="Hidden Expiry"
    cvv_show="Encrypted CVV"
    for card in ${list_bcard} ; do
      echo "bcard/${card},${owner_show},${num_card_show},${expiry_show},${cvv_show}" >> ${pwsh_vault_cache_bcard}
    done
  fi
  cd ${pwsh_vault}
  if [ ${list_notes_count} -ne 0 ] ; then
    list_notes=$(ls -1 notes/)
    note_show="Encrypted Note"
    for note in ${list_notes} ; do
      echo "notes/${note},${note_show}" >> ${pwsh_vault_cache_notes}
    done
  fi
  run_all_list_process_extracted_vault | pwsh-vaultm -p "  List Entries:"
}

function change_masterkey_vault() {
  clear
  load_masterkey=$(cat ${pwsh_vault_masterkey} | cut -d ";" -f 2)
  masterkey_loaded=$(vault_key_decrypt "${load_masterkey}")
  count_logins=$(ls -1 ${pwsh_vault}/logins/ | wc -l)
  count_notes=$(ls -1 ${pwsh_vault}/notes/ | wc -l)
  count_bcard=$(ls -1 ${pwsh_vault}/bcard/ | wc -l)
  echo ""
  echo "# pwsh-vault ${VERSION}"
  echo ""
  current_masterkey=$(echo > /dev/null | pwsh-vaultm -p "  Enter Current MasterKey:")
  if [ "${current_masterkey}" == "${masterkey_loaded}" ] ; then
    echo ""
    masterkey_input=$(echo > /dev/null | pwsh-vaultm -p "  Enter New MasterKey:")
    masterkey_reinput=$(echo > /dev/null | pwsh-vaultm -p "  Re-Enter New MasterKey:")
    if [ "${masterkey_input}" == "${masterkey_reinput}" ] ; then
      echo ""
      masterkey_name=$(vault_key_encrypt "Masterkey")
      masterkey_gen=$(vault_key_encrypt "${masterkey_input}")
      echo "${masterkey_name};${masterkey_gen}" > ${pwsh_vault_masterkey}
      echo "# Applying the change in ${pwsh_vault_masterkey}"
      if [ ${count_logins} -ne 0 ] ; then
        list_logins=$(ls -1 ${pwsh_vault}/logins/)
        for login in ${list_logins} ; do
          login_content=$(cat ${pwsh_vault}/logins/${login}/login | tail -1)
          echo "${masterkey_name};${masterkey_gen}" > ${pwsh_vault}/logins/${login}/login
          echo "${login_content}" >> ${pwsh_vault}/logins/${login}/login
          echo "# Applying the change in ${pwsh_vault}/logins/${login}/login"
          password_content=$(cat ${pwsh_vault}/logins/${login}/password | tail -1)
          echo "${masterkey_name};${masterkey_gen}" > ${pwsh_vault}/logins/${login}/password
          echo "${password_content}" >> ${pwsh_vault}/logins/${login}/password
          echo "# Applying the change in ${pwsh_vault}/logins/${login}/password"
          url_content=$(cat ${pwsh_vault}/logins/${login}/url | tail -1)
          echo "${masterkey_name};${masterkey_gen}" > ${pwsh_vault}/logins/${login}/url
          echo "${url_content}" >> ${pwsh_vault}/logins/${login}/url
          echo "# Applying the change in ${pwsh_vault}/logins/${login}/url"
          otp_content=$(cat ${pwsh_vault}/logins/${login}/otp | tail -1)
          echo "${masterkey_name};${masterkey_gen}" > ${pwsh_vault}/logins/${login}/otp
          echo "${otp_content}" >> ${pwsh_vault}/logins/${login}/otp
          echo "# Applying the change in ${pwsh_vault}/logins/${login}/otp"
        done
      fi
      if [ ${count_bcard} -ne 0 ] ; then
        list_bcard=$(ls -1 ${pwsh_vault}/bcard/)
        for card in ${list_bcard} ; do
          owner_content=$(cat ${pwsh_vault}/bcard/${card}/owner | tail -1)
          echo "${masterkey_name};${masterkey_gen}" > ${pwsh_vault}/bcard/${card}/owner
          echo "${owner_content}" >> ${pwsh_vault}/bcard/${card}/owner
          echo "# Applying the change in ${pwsh_vault}/bcard/${card}/owner"
          card_content=$(cat ${pwsh_vault}/bcard/${card}/card | tail -1)
          echo "${masterkey_name};${masterkey_gen}" > ${pwsh_vault}/bcard/${card}/card
          echo "${card_content}" >> ${pwsh_vault}/bcard/${card}/card
          echo "# Applying the change in ${pwsh_vault}/bcard/${card}/card"
          expiry_content=$(cat ${pwsh_vault}/bcard/${card}/expiry | tail -1)
          echo "${masterkey_name};${masterkey_gen}" > ${pwsh_vault}/bcard/${card}/expiry
          echo "${expiry_content}" >> ${pwsh_vault}/bcard/${card}/expiry
          echo "# Applying the change in ${pwsh_vault}/bcard/${card}/expiry"
          cvv_content=$(cat ${pwsh_vault}/bcard/${card}/cvv | tail -1)
          echo "${masterkey_name};${masterkey_gen}" > ${pwsh_vault}/bcard/${card}/cvv
          echo "${cvv_content}" >> ${pwsh_vault}/bcard/${card}/cvv
          echo "# Applying the change in ${pwsh_vault}/bcard/${card}/cvv"
        done
      fi
      if [ ${count_notes} -ne 0 ] ; then
        list_notes=$(ls -1 ${pwsh_vault}/notes/)
        for note in ${list_notes} ; do
          note_content=$(cat ${pwsh_vault}/notes/${note}/note | tail -1)
          echo "${masterkey_name};${masterkey_gen}" > ${pwsh_vault}/notes/${note}/note
          echo "${note_content}" >> ${pwsh_vault}/notes/${note}/note
          echo "# Applying the change in ${pwsh_vault}/notes/${note}/note"
        done
      fi
      echo > /dev/null | pwsh-vaultm -p "  New MasterKey configuration finished $(generate_spaces 50)"
    else
      echo > /dev/null | pwsh-vaultm -p "  Both passwords do not match $(generate_spaces 60)"
    fi
  else
    echo > /dev/null | pwsh-vaultm -p "  Wrong MasterKey $(generate_spaces 70)"
  fi
}

function remove_entry_vault() {
  vault_remove_entry=$(list_folders_pwsh_vault | pwsh-vaultm -p "  Remove Entry:")
  vault_remove_entry=$(echo ${vault_remove_entry} | cut -c5-999)
  if [ -z "${vault_remove_entry}" ] ; then
    echo "# Canceled Remove Entry"
  else
    if [ -d "${pwsh_vault}/${vault_remove_entry}" ] ; then
      are_you_sure=$(echo -e "No\nYes" | pwsh-vaultm -p " Selected: ${vault_remove_entry}, Are you sure?:")
      if [ "${are_you_sure}" == "Yes" ] ; then
        rm -rf "${pwsh_vault}/${vault_remove_entry}"
        echo > /dev/null | pwsh-vaultm -p "  Entry ${vault_remove_entry} Removed $(generate_spaces 55)"
      fi
    else
      echo > /dev/null | pwsh-vaultm -p "  Entry ${vault_remove_entry} does no exist $(generate_spaces 55)"
    fi
  fi
}

function edit_entry_vault() {
  vault_edit_entry=$(list_folders_pwsh_vault | pwsh-vaultm -p "  Edit Entry:")
  vault_edit_entry=$(echo ${vault_edit_entry} | cut -c5-999)
  if [ -z "${vault_edit_entry}" ] ; then
    echo "# Canceled Edit Entry"
  else
    if [ -d "${pwsh_vault}/${vault_edit_entry}" ] ; then
      echo ""
      echo "# Selected Entry ${vault_edit_entry}"
      masterkey_load=$(cat ${pwsh_vault_masterkey})
      if [ -f "${pwsh_vault}/${vault_edit_entry}/login" ] ; then
        read_username=$(cat ${pwsh_vault}/${vault_edit_entry}/login | tail -1 | cut -d ";" -f 2)
        read_userame_dc=$(vault_key_decrypt "${read_username}")
        name_username=$(echo > /dev/null | pwsh-vaultm -p "爵  Enter Username (Default: ${read_userame_dc}):")
        if [ ! -z "${name_username}" ] ; then
          name_username=$(vault_key_encrypt "${name_username}")
          username_text=$(vault_key_encrypt "Username")
          echo "${masterkey_load}" > "${pwsh_vault}/${vault_edit_entry}/login"
          echo "${username_text};${name_username}" >> "${pwsh_vault}/${vault_edit_entry}/login"
        fi
      fi
      if [ -f "${pwsh_vault}/${vault_edit_entry}/password" ] ; then
        read_password=$(cat ${pwsh_vault}/${vault_edit_entry}/password | tail -1 | cut -d ";" -f 2)
        read_password_dc=$(vault_key_decrypt "${read_password}")
        name_password=$(echo > /dev/null | pwsh-vaultm -p "爵  Enter Password (Default: ${read_password_dc}):")
        if [ ! -z "${name_password}" ] ; then
          name_password=$(vault_key_encrypt "${name_password}")
          password_text=$(vault_key_encrypt "Password")
          echo "${masterkey_load}" > "${pwsh_vault}/${vault_edit_entry}/password"
          echo "${password_text};${name_password}" >> "${pwsh_vault}/${vault_edit_entry}/password"
        fi
      fi
      if [ -f "${pwsh_vault}/${vault_edit_entry}/url" ] ; then
        read_url=$(cat ${pwsh_vault}/${vault_edit_entry}/url | tail -1 | cut -d ";" -f 2)
        read_url_dc=$(vault_key_decrypt "${read_url}")
        name_url=$(echo > /dev/null | pwsh-vaultm -p "爵  Enter URL (Default: ${read_url_dc}):")
        if [ ! -z "${name_url}" ] ; then
          name_url=$(vault_key_encrypt "${name_url}")
          url_text=$(vault_key_encrypt "URL")
          echo "${masterkey_load}" > "${pwsh_vault}/${vault_edit_entry}/url"
          echo "${url_text};${name_url}" >> "${pwsh_vault}/${vault_edit_entry}/url"
        fi
      fi
      if [ -f "${pwsh_vault}/${vault_edit_entry}/otp" ] ; then
        read_otp=$(cat ${pwsh_vault}/${vault_edit_entry}/otp | tail -1 | cut -d ";" -f 2)
        read_otp_dc=$(vault_key_decrypt "${read_otp}")
        name_otp=$(echo > /dev/null | pwsh-vaultm -p "爵  Enter OTP (Default: None):")
        if [ ! -z "${name_otp}" ] ; then
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
        name_owner=$(echo > /dev/null | pwsh-vaultm -p "  Enter Owner (Default: ${read_owner_dc}):")
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
        name_card=$(echo > /dev/null | pwsh-vaultm -p "  Enter Card Number (Default: ${read_card_dc}):")
        if [ ! -z "${name_card}" ] ; then
          name_card=$(vault_key_encrypt "${name_card}")
          card_text=$(vault_key_encrypt "Card")
          echo "${masterkey_load}" > "${pwsh_vault}/${vault_edit_entry}/card"
          echo "${card_text};${name_card}" >> "${pwsh_vault}/${vault_edit_entry}/card"
        fi
      fi
      if [ -f "${pwsh_vault}/${vault_edit_entry}/expiry" ] ; then
        read_expiry=$(cat ${pwsh_vault}/${vault_edit_entry}/expiry | tail -1 | cut -d ";" -f 2)
        read_expiry_dc=$(vault_key_decrypt "${read_expiry}")
        name_expiry=$(echo > /dev/null | pwsh-vaultm -p "  Enter Expiry Date (Default: ${read_expiry_dc}):")
        if [ ! -z "${name_expiry}" ] ; then
          name_expiry=$(vault_key_encrypt "${name_expiry}")
          expiry_text=$(vault_key_encrypt "Expiry")
          echo "${masterkey_load}" > "${pwsh_vault}/${vault_edit_entry}/expiry"
          echo "${expiry_text};${name_expiry}" >> "${pwsh_vault}/${vault_edit_entry}/expiry"
        fi
      fi
      if [ -f "${pwsh_vault}/${vault_edit_entry}/cvv" ] ; then
        read_cvv=$(cat ${pwsh_vault}/${vault_edit_entry}/cvv | tail -1 | cut -d ";" -f 2)
        read_cvv_dc=$(vault_key_decrypt "${read_cvv}")
        name_cvv=$(echo > /dev/null | pwsh-vaultm -p "  Enter CVV (Default: ${read_cvv_dc}):")
        if [ ! -z "${name_cvv}" ] ; then
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
        name_note=$(echo > /dev/null | pwsh-vaultm -p "  Enter Note (Default: ${read_note_dc}):")
        if [ ! -z "${name_note}" ] ; then
          name_note=$(removeSpaces "${name_note}")
          name_note=$(vault_key_encrypt "${name_note}")
          note_text=$(vault_key_encrypt "note")
          echo "${masterkey_load}" > "${pwsh_vault}/${vault_edit_entry}/note"
          echo "${note_text};${name_note}" >> "${pwsh_vault}/${vault_edit_entry}/note"
        fi
      fi
      echo > /dev/null | pwsh-vaultm -p "  ENTRY EDITED: ${vault_edit_entry} $(generate_spaces 60)"
      edit_entry_vault
    else
      echo "# Entry ${vault_edit_entry} does no exist"
      edit_entry_vault
    fi
  fi
}

function search_entries_menu_show() {
  echo "爵  Search Login/Website Entry"
  echo "爵  Search Login/Website Entry (Show OTP)"
  echo "  Search Credit/Bank Card Entry"
  echo "  Search Note Entry"
}

function search_result_show_login_otp() {
  result=$(echo ${1} | cut -d " " -f 2 | cut -d "/" -f 2)
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
    echo >> ${pwsh_vault_clipboard_copy}
    echo "* Name Entry: logins/${result}" >> ${pwsh_vault_clipboard_copy}
    echo "* Login: ${username_decrypt}" >> ${pwsh_vault_clipboard_copy}
    echo "* Password: ${password_decrypt}" >> ${pwsh_vault_clipboard_copy}
    echo "* URL: ${url_decrypt}" >> ${pwsh_vault_clipboard_copy}
    echo "* OTP: ${otp_decrypt}" >> ${pwsh_vault_clipboard_copy}
    echo "  Name Entry: logins/${result}"
    echo "﫻  Login: ${username_decrypt}"
    echo "  Password: ${password_decrypt}"
    echo "爵  URL: ${url_decrypt}"
    echo "勒  OTP: ${otp_decrypt}"
    echo ""
    echo "  Data has been copied to ${pwsh_vault_clipboard_copy} $(generate_spaces 30)"
  else
    echo "  Entry logins/${result} CORRUPTED $(generate_spaces 60)"
  fi
}

function search_result_show_login() {
  result=$(echo ${1} | cut -d " " -f 2 | cut -d "/" -f 2)
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
    echo >> ${pwsh_vault_clipboard_copy}
    echo "* Name Entry: logins/${result}" >> ${pwsh_vault_clipboard_copy}
    echo "* Login: ${username_decrypt}" >> ${pwsh_vault_clipboard_copy}
    echo "* Password: ${password_decrypt}" >> ${pwsh_vault_clipboard_copy}
    echo "* URL: ${url_decrypt}" >> ${pwsh_vault_clipboard_copy}
    echo "* OTP: ${otp_decrypt}" >> ${pwsh_vault_clipboard_copy}
    echo "  Name Entry: logins/${result}"
    echo "﫻  Login: ${username_decrypt}"
    echo "  Password: ${password_decrypt}"
    echo "爵  URL: ${url_decrypt}"
    echo "勒  OTP: ${otp_decrypt}"
    echo ""
    echo "  Data has been copied to ${pwsh_vault_clipboard_copy} $(generate_spaces 30)"
  else
    echo "  Entry logins/${result} CORRUPTED $(generate_spaces 60)"
  fi
}

function search_result_show_bcard() {
  result=$(echo ${1} | cut -d " " -f 2 | cut -d "/" -f 2)
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
    echo >> ${pwsh_vault_clipboard_copy}
    echo "* Name Entry: bcard/${result}" >> ${pwsh_vault_clipboard_copy}
    echo "* Owner: ${owner_decrypt}" >> ${pwsh_vault_clipboard_copy}
    echo "* Card: ${card_decrypt}" >> ${pwsh_vault_clipboard_copy}
    echo "* Expiry: ${expiry_decrypt}" >> ${pwsh_vault_clipboard_copy}
    echo "* CVV: ${cvv_decrypt}" >> ${pwsh_vault_clipboard_copy}
    echo "  Name Entry: bcard/${result}"
    echo "  Owner: ${owner_decrypt}"
    echo "  Card: ${card_decrypt}"
    echo "  Expiry: ${expiry_decrypt}"
    echo "况  CVV: ${cvv_decrypt}"
    echo ""
    echo "  Data has been copied to ${pwsh_vault_clipboard_copy} $(generate_spaces 30)"
  else
    echo "  Entry bcard/${result} CORRUPTED $(generate_spaces 60)"
  fi
}

function search_result_show_note() {
  result=$(echo ${1} | cut -d " " -f 2 | cut -d "/" -f 2)
  corrupted_result=$(check_corrupted_entry_vault ${result} notes)
  if [ ${corrupted_result} -eq 0 ] ; then
    note_decrypt=$(cat notes/${result}/note | tail -1 | cut -d ";" -f 2)
    note_decrypt=$(vault_key_decrypt "${note_decrypt}")
    note_decrypt=$(restoreSpaces "${note_decrypt}")
    echo >> ${pwsh_vault_clipboard_copy}
    echo "* Name Entry: notes/${result}" >> ${pwsh_vault_clipboard_copy}
    echo "* Note: ${note_decrypt}" >> ${pwsh_vault_clipboard_copy}
    echo "  Name Entry: notes/${result}"
    echo "  Note: ${note_decrypt}"
    echo ""
    echo "  Data has been copied to ${pwsh_vault_clipboard_copy} $(generate_spaces 30)"
  else
    echo "  Entry notes/${result} CORRUPTED $(generate_spaces 60)"
  fi
}

function search_entries_vault() {
  clear
  cd ${pwsh_vault}
  echo ""
  echo "# pwsh-vault ${VERSION}"
  echo ""
  echo "# Preparing Vault List Entries"
  echo ""
  rm -rf ${pwsh_vault_cache_logins}
  rm -rf ${pwsh_vault_cache_logins_otp}
  rm -rf ${pwsh_vault_cache_bcard}
  rm -rf ${pwsh_vault_cache_notes}
  list_logins_count=$(ls -1 logins/ | wc -l)
  list_bcard_count=$(ls -1 bcard/ | wc -l)
  list_notes_count=$(ls -1 notes/ | wc -l)
  if [ ${list_logins_count} -ne 0 ] ; then
    list_logins=$(ls -1 logins/)
    for login in ${list_logins} ; do
      username_show="Hidden User"
      password_show="Encrypted Password"
      url_show="Hidden URL"
      otp_show="Hidden OTP"
      echo "logins/${login},${username_show},${password_show},${url_show},${otp_show}" >> ${pwsh_vault_cache_logins_otp}
      echo "logins/${login},${username_show},${password_show},${url_show},${otp_show}" >> ${pwsh_vault_cache_logins}
    done
  fi
  cd ${pwsh_vault}
  if [ ${list_bcard_count} -ne 0 ] ; then
    list_bcard=$(ls -1 bcard/)
    for card in ${list_bcard} ; do
      owner_show="Hidden Owner"
      num_card_show="Hidden Card"
      expiry_show="Hidden Expiry"
      cvv_show="Encrypted CVV"
      echo "bcard/${card},${owner_show},${num_card_show},${expiry_show},${cvv_show}" >> ${pwsh_vault_cache_bcard}
    done
  fi
  cd ${pwsh_vault}
  if [ ${list_notes_count} -ne 0 ] ; then
    list_notes=$(ls -1 notes/)
    for note in ${list_notes} ; do
      note_show="Encrypted Note"
      echo "notes/${note},${note_show}" >> ${pwsh_vault_cache_notes}
    done
  fi
  search_entry=$(search_entries_menu_show | pwsh-vaultm -p "  Search Entry:")
  if [ "${search_entry}" == "爵  Search Login/Website Entry" ] ; then
    string_search=$(echo > /dev/null | pwsh-vaultm -p "  Type a string to search:")
    if [ -z "${string_search}" ] ; then
      rm -rf ${pwsh_vault_cache_temp}
      touch ${pwsh_vault_cache_temp}
      cat ${pwsh_vault_cache_logins} >> ${pwsh_vault_cache_temp}
      cat ${pwsh_vault_cache_temp} > ${pwsh_vault_cache_logins}
      lines_read=$(cat ${pwsh_vault_cache_logins} 2> /dev/null | wc -l)
      if [ ${lines_read} -eq 0 ] ; then
        echo > /dev/null | pwsh-vaultm -p "  No Entries to Show $(generate_spaces 70)"
      else
        copy_clipboard=$(process_extracted_vault_logins | pwsh-vaultm -p "  Search Results:")
        if [ -z "${copy_clipboard}" ] ; then
          echo "# Ignore copy clipboard"
        else
          search_result_show_login "${copy_clipboard}" | pwsh-vaultm -p "  Result:"
        fi
      fi
      rm -rf ${pwsh_vault_cache_logins}
      search_entries_vault
    else
      rm -rf ${pwsh_vault_cache_temp}
      touch ${pwsh_vault_cache_temp}
      cat ${pwsh_vault_cache_logins} | grep -i "${string_search}" >> ${pwsh_vault_cache_temp}
      cat ${pwsh_vault_cache_temp} > ${pwsh_vault_cache_logins}
      lines_read=$(cat ${pwsh_vault_cache_logins} 2> /dev/null | wc -l)
      if [ ${lines_read} -eq 0 ] ; then
        echo > /dev/null | pwsh-vaultm -p "  No Entries to Show $(generate_spaces 70)"
      else
        copy_clipboard=$(process_extracted_vault_logins | pwsh-vaultm -p "  Search Results:")
        if [ -z "${copy_clipboard}" ] ; then
          echo "# Ignore copy clipboard"
        else
          search_result_show_login "${copy_clipboard}" | pwsh-vaultm -p "  Result:"
        fi
      fi
      rm -rf ${pwsh_vault_cache_logins}
      search_entries_vault
    fi
  elif [ "${search_entry}" == "爵  Search Login/Website Entry (Show OTP)" ] ; then
    string_search=$(echo > /dev/null | pwsh-vaultm -p "  Type a string to search:")
    if [ -z "${string_search}" ] ; then
      rm -rf ${pwsh_vault_cache_temp}
      touch ${pwsh_vault_cache_temp}
      cat ${pwsh_vault_cache_logins_otp} >> ${pwsh_vault_cache_temp}
      cat ${pwsh_vault_cache_temp} > ${pwsh_vault_cache_logins}
      lines_read=$(cat ${pwsh_vault_cache_logins} 2> /dev/null | wc -l)
      if [ ${lines_read} -eq 0 ] ; then
        echo > /dev/null | pwsh-vaultm -p "  No Entries to Show $(generate_spaces 70)"
      else
        copy_clipboard=$(process_extracted_vault_logins | pwsh-vaultm -p "  Search Results:")
        if [ -z "${copy_clipboard}" ] ; then
          echo "# Ignore copy clipboard"
        else
          search_result_show_login_otp "${copy_clipboard}" | pwsh-vaultm -p "  Result:"
        fi
      fi
      rm -rf ${pwsh_vault_cache_logins}
      search_entries_vault
    else
      rm -rf ${pwsh_vault_cache_temp}
      touch ${pwsh_vault_cache_temp}
      cat ${pwsh_vault_cache_logins_otp} | grep -i "${string_search}" >> ${pwsh_vault_cache_temp}
      cat ${pwsh_vault_cache_temp} > ${pwsh_vault_cache_logins}
      lines_read=$(cat ${pwsh_vault_cache_logins} 2> /dev/null | wc -l)
      if [ ${lines_read} -eq 0 ] ; then
        echo > /dev/null | pwsh-vaultm -p "  No Entries to Show $(generate_spaces 70)"
      else
        copy_clipboard=$(process_extracted_vault_logins | pwsh-vaultm -p "  Search Results:")
        if [ -z "${copy_clipboard}" ] ; then
          echo "# Ignore copy clipboard"
        else
          search_result_show_login_otp "${copy_clipboard}" | pwsh-vaultm -p "  Result:"
        fi
      fi
      rm -rf ${pwsh_vault_cache_logins}
      rm -rf ${pwsh_vault_cache_logins_otp}
      search_entries_vault
    fi
    
  elif [ "${search_entry}" == "  Search Credit/Bank Card Entry" ] ; then
    string_search=$(echo > /dev/null | pwsh-vaultm -p "  Type a string to search:")
    if [ -z "${string_search}" ] ; then
      rm -rf ${pwsh_vault_cache_temp}
      touch ${pwsh_vault_cache_temp}
      cat ${pwsh_vault_cache_bcard} >> ${pwsh_vault_cache_temp}
      cat ${pwsh_vault_cache_temp} > ${pwsh_vault_cache_bcard}
      lines_read=$(cat ${pwsh_vault_cache_bcard} 2> /dev/null | wc -l)
      if [ ${lines_read} -eq 0 ] ; then
        echo > /dev/null | pwsh-vaultm -p "  No Entries to Show $(generate_spaces 70)"
      else
        copy_clipboard=$(process_extracted_vault_bcard | pwsh-vaultm -p "  Search Results:")
        if [ -z "${copy_clipboard}" ] ; then
          echo "# Ignore copy clipboard"
        else
          search_result_show_bcard "${copy_clipboard}" | pwsh-vaultm -p "  Result:"
        fi
      fi
      rm -rf ${pwsh_vault_cache_bcard}
      search_entries_vault
    else
      rm -rf ${pwsh_vault_cache_temp}
      touch ${pwsh_vault_cache_temp}
      cat ${pwsh_vault_cache_bcard} | grep -i "${string_search}" >> ${pwsh_vault_cache_temp}
      cat ${pwsh_vault_cache_temp} > ${pwsh_vault_cache_bcard}
      lines_read=$(cat ${pwsh_vault_cache_bcard} 2> /dev/null | wc -l)
      if [ ${lines_read} -eq 0 ] ; then
        echo > /dev/null | pwsh-vaultm -p "  No Entries to Show $(generate_spaces 70)"
      else
        copy_clipboard=$(process_extracted_vault_bcard | pwsh-vaultm -p "  Search Results:")
        if [ -z "${copy_clipboard}" ] ; then
          echo "# Ignore copy clipboard"
        else
          search_result_show_bcard "${copy_clipboard}" | pwsh-vaultm -p "  Result:"
        fi
      fi
      rm -rf ${pwsh_vault_cache_bcard}
      search_entries_vault
    fi
  elif [ "${search_entry}" == "  Search Note Entry" ] ; then
    string_search=$(echo > /dev/null | pwsh-vaultm -p "  Type a string to search:")
    if [ -z "${string_search}" ] ; then
      rm -rf ${pwsh_vault_cache_temp}
      touch ${pwsh_vault_cache_temp}
      cat ${pwsh_vault_cache_notes} >> ${pwsh_vault_cache_temp}
      cat ${pwsh_vault_cache_temp} > ${pwsh_vault_cache_notes}
      lines_read=$(cat ${pwsh_vault_cache_notes} 2> /dev/null | wc -l)
      if [ ${lines_read} -eq 0 ] ; then
        echo > /dev/null | pwsh-vaultm -p "  No Entries to Show $(generate_spaces 70)"
      else
        copy_clipboard=$(process_extracted_vault_notes | pwsh-vaultm -p "  Search Results:")
        if [ -z "${copy_clipboard}" ] ; then
          echo "# Ignore copy clipboard"
        else
          search_result_show_note "${copy_clipboard}" | pwsh-vaultm -p "  Result:"
        fi
      fi
      rm -rf ${pwsh_vault_cache_notes}
      search_entries_vault
    else
      rm -rf ${pwsh_vault_cache_temp}
      touch ${pwsh_vault_cache_temp}
      cat ${pwsh_vault_cache_notes} | grep -i "${string_search}" >> ${pwsh_vault_cache_temp}
      cat ${pwsh_vault_cache_temp} > ${pwsh_vault_cache_notes}
      lines_read=$(cat ${pwsh_vault_cache_notes} 2> /dev/null | wc -l)
      if [ ${lines_read} -eq 0 ] ; then
        echo > /dev/null | pwsh-vaultm -p "  No Entries to Show $(generate_spaces 70)"
      else
        copy_clipboard=$(process_extracted_vault_notes | pwsh-vaultm -p "  Search Results:")
        if [ -z "${copy_clipboard}" ] ; then
          echo "# Ignore copy clipboard"
        else
          search_result_show_note "${copy_clipboard}" | pwsh-vaultm -p "  Result:"
        fi
      fi
      rm -rf ${pwsh_vault_cache_notes}
      search_entries_vault
    fi
  else
    echo > /dev/null
  fi
}

function show_pwsh_vault_main() {
  echo "  Create Entry"
  echo "  Edit Entry"
  echo "  Search Entry"
  echo "  List Entries"
  echo "  Remove Entry"
  echo "  Change Masterkey"
  echo "  Generate Password"
  echo "  Export Vault"
  echo "  Import Vault"
  echo "  About"
  echo "  Quit"
}

function pwsh_vault_main() {
  vault_main_init=0
  while [ ${vault_main_init} -eq 0 ] ;do
    vault_main_option=$(show_pwsh_vault_main | pwsh-vaultm -p "ﱱ  pwsh-vault ${VERSION}")
    if [ "${vault_main_option}" == "  Create Entry" ] ; then
      create_entries_menu
    elif [ "${vault_main_option}" == "  Edit Entry" ] ; then
      edit_entry_vault
    elif [ "${vault_main_option}" == "  Search Entry" ] ; then
      search_entries_vault
    elif [ "${vault_main_option}" == "  List Entries" ] ; then
      list_entries_vault
    elif [ "${vault_main_option}" == "  Remove Entry" ] ; then
      remove_entry_vault
    elif [ "${vault_main_option}" == "  About" ] ; then
      pwsh_vault_about
    elif [ "${vault_main_option}" == "  Change Masterkey" ] ; then
      change_masterkey_vault
    elif [ "${vault_main_option}" == "  Generate Password" ] ; then
      generate_password_menu
    elif [ "${vault_main_option}" == "  Export Vault" ] ; then
      export_pwsh_vault
    elif [ "${vault_main_option}" == "  Import Vault" ] ; then
      import_pwsh_vault
    elif [ "${vault_main_option}" == "  Quit" ] ; then
      vault_main_init=1
      exit
    else
      if [ -z ${vault_main_option} ] ; then
        vault_main_init=1
      fi
    fi
  done
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
if [ "${1}" == "--help" ] ; then
  pwsh_vault_help
elif [ "${1}" == "--export" ] ; then
  if [ "${2}" == "--encrypt" ] ; then
    export_pwsh_vault_param_encrypt
  else
    export_pwsh_vault_param
  fi
elif [ "${1}" == "--import" ] ; then
  import_pwsh_vault_param "${2}"
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

