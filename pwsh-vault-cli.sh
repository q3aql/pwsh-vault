#!/bin/bash

#############################################################
# pwsh-vault-cli - Password Manager written with Bash (CLI) #
# Author: q3aql                                             #
# Contact: q3aql@duck.com                                   #
# License: GPL v2.0                                         #
# Last-Change: 12-06-20222                                  #
# ###########################################################
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

function generate_password_menu() {
  clear
  size_password=20
  echo ""
  echo "# pwsh-vault-cli ${VERSION}"
  echo ""
  echo -n "# Set the password size (Default: 20): " ; read size_password
  generate_password "${size_password}"
}

function init_masterkey() {
  echo ""
  echo "# pwsh-vault-cli ${VERSION}"
  echo ""
  if [ -f ${pwsh_vault_masterkey} ] ; then
    echo -n "# Enter MasterKey Vault: " ; read -s read_masterkey_vault
    read_masterkey=$(cat ${pwsh_vault_masterkey} | cut -d ";" -f 2)
    decrypt_masterkey=$(vault_key_decrypt "${read_masterkey}")
    if [ "${decrypt_masterkey}" == "${read_masterkey_vault}" ] ; then
      echo "# MasterKey is valid"
    else
      echo "" && echo ""
      echo "# Wrong MasterKey"
      exit
    fi
  else
    echo "# A masterkey has not yet been defined"
    echo -n "# Enter New MasterKey: " ; read -s masterkey_input
    echo ""
    echo -n "# Re-Enter New MasterKey: " ; read -s masterkey_reinput
    if [ "${masterkey_input}" == "${masterkey_reinput}" ] ; then
      echo ""
      masterkey_name=$(vault_key_encrypt "Masterkey")
      masterkey_gen=$(vault_key_encrypt "${masterkey_input}")
      echo "${masterkey_name};${masterkey_gen}" > ${pwsh_vault_masterkey}
      echo ""
      echo "# New MasterKey defined correctly"
    else
      echo "" && echo ""
      echo "# Both passwords do not match"
      exit
    fi
  fi
}

function create_login_vault_entry() {
  clear
  echo ""
  echo "# pwsh-vault-cli ${VERSION}"
  echo ""
  name_login_entry=0
  masterkey_load=$(cat ${pwsh_vault_masterkey})
  while [ ${name_login_entry} -eq 0 ] ; do
    echo -n "# Enter Name for Login Entry: " ; read name_entry
    if [ ! -z "${name_entry}" ] ; then
      name_entry=$(removeSpaces "${name_entry}")
      mkdir -p "${pwsh_vault}/logins/${name_entry}"
      name_login_entry=1
    fi
  done
  username_entry=0
  while [ ${username_entry} -eq 0 ] ; do
    echo -n "# Enter Username: " ; read name_username
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
    echo -n "# Enter Password: " ; read name_password
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
    echo -n "# Enter URL: " ; read name_url
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
    echo -n "# Enter OTP (Default: None): " ; read name_otp
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
  name_username=$(vault_key_decrypt "${name_username}")
  name_password=$(vault_key_decrypt "${name_password}")
  name_url=$(vault_key_decrypt "${name_url}")
  name_otp=$(vault_key_decrypt "${name_otp}")
  echo ""
  echo "# ENTRY CREATED:"
  echo ""
  echo "# Name Entry: ${name_entry}"
  echo "# Username: ${name_username}"
  echo "# Password: ${name_password}"
  echo "# URL: ${name_url}"
  echo "# OTP: ${name_otp}"
  echo ""
  echo -n "# Press enter key to continue " ; read enter_continue
  create_entries_menu
}

function create_bcard_vault_entry() {
  clear
  echo ""
  echo "# pwsh-vault-cli ${VERSION}"
  echo ""
  name_bcard_entry=0
  masterkey_load=$(cat ${pwsh_vault_masterkey})
  while [ ${name_bcard_entry} -eq 0 ] ; do
    echo -n "# Enter Name for Bcard Entry: " ; read name_entry
    if [ ! -z "${name_entry}" ] ; then
      name_entry=$(removeSpaces "${name_entry}")
      mkdir -p "${pwsh_vault}/bcard/${name_entry}"
      name_bcard_entry=1
    fi
  done
  owner_entry=0
  while [ ${owner_entry} -eq 0 ] ; do
    echo -n "# Enter Owner: " ; read name_owner
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
    echo -n "# Enter Card Number (XXXX-XXXX-XXXX-XXXX): " ; read name_card
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
    echo -n "# Enter Expiry Date (MM/YY): " ; read name_expiry
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
    echo -n "# Enter CVV: " ; read name_cvv
    if [ ! -z "${name_cvv}" ] ; then
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
  echo ""
  echo "# ENTRY CREATED:"
  echo ""
  echo "# Name Entry: ${name_entry}"
  echo "# Owner: ${name_owner}"
  echo "# Card: ${name_card}"
  echo "# Expiry: ${name_expiry}"
  echo "# CVV: ${name_cvv}"
  echo ""
  echo -n "# Press enter key to continue " ; read enter_continue
  create_entries_menu
}

function create_note_vault_entry() {
  clear
  echo ""
  echo "# pwsh-vault-cli ${VERSION}"
  echo ""
  name_note_entry=0
  masterkey_load=$(cat ${pwsh_vault_masterkey})
  while [ ${name_note_entry} -eq 0 ] ; do
    echo -n "# Enter Name for Note Entry: " ; read name_entry
    if [ ! -z "${name_entry}" ] ; then
      name_entry=$(removeSpaces "${name_entry}")
      mkdir -p "${pwsh_vault}/notes/${name_entry}"
      name_note_entry=1
    fi
  done
  note_entry=0
  while [ ${note_entry} -eq 0 ] ; do
    echo -n "# Enter Note: " ; read name_note
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
  echo ""
  echo "# ENTRY CREATED:"
  echo ""
  echo "# Name Entry: ${name_entry}"
  echo "# Note: ${name_note}"
  echo ""
  echo -n "# Press enter key to continue " ; read enter_continue
  create_entries_menu
}

function create_entries_menu() {
  clear
  echo ""
  echo "# pwsh-vault-cli ${VERSION}"
  echo ""
  echo "# Create New Entry:"
  echo ""
  echo " l --> Login/Website Entry"
  echo " b --> Credit/Bank Card Entry"
  echo " n --> Note Entry"
  echo ""
  echo " r --> Back"
  echo ""
  echo -n "# Type an option (Default: r): " ; read new_entry
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
  echo -n "# Set password when exporting? (Default: n) (y/n): " ; read export_vault
  if [ "${export_vault}" == "y" ] ; then
    zip -e -r ${HOME}/pwsh-vault-export_${name_date}.zip *
    error=$?
    if [ ${error} -eq 0 ] ; then
      echo "# Vault exported to ${HOME}/pwsh-vault-export_${name_date}.zip"
      echo -n "# Press enter key to continue " ; read enter_continue
    else
      echo "# Error Exporting Vault"
      rm -rf ${HOME}/pwsh-vault-export_${name_date}.zip
      echo -n "# Press enter key to continue " ; read enter_continue
    fi
  else
    zip -r ${HOME}/pwsh-vault-export_${name_date}.zip *
    error=$?
    if [ ${error} -eq 0 ] ; then
      echo "# Vault exported to ${HOME}/pwsh-vault-export_${name_date}.zip"
      echo -n "# Press enter key to continue " ; read enter_continue
    else
      echo "# Error Exporting Vault"
      rm -rf ${HOME}/pwsh-vault-export_${name_date}.zip
      echo -n "# Press enter key to continue " ; read enter_continue
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
  zip_file_exist=0
  while [ ${zip_file_exist} -eq 0 ] ; do
    echo -n "# Enter path of zip file: " ; read zip_file
    if [ -f "${zip_file}" ] ; then
      echo "# Importing vault from zip file"
      unzip -o "${zip_file}" -d ${pwsh_vault}
      error=$?
      if [ ${error} -eq 0 ] ; then
        echo "# Vault imported from ${zip_file}"
        zip_file_exist=1
        echo -n "# Press enter key to continue " ; read enter_continue
      else
        echo "# Error Importing Vault"
        zip_file_exist=1
        echo -n "# press enter key to continue " ; read enter_continue
      fi
    else
      if [ -z "${zip_file}" ] ; then
        echo > /dev/null
      else
        echo "# Vault ${zip_file} does not exist"
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

function pwsh_vault_about() {
    clear
    echo ""
    echo "# Software: pwsh-vault-cli ${VERSION}"
    echo "# Contact: q3aql <q3aql@duck.com>"
    echo "# LICENSE: GPLv2.0"
    echo ""
    echo -n "# Press enter key to continue " ; read enter_continue
}

function pwsh_vault_help() {
    echo ""
    echo "# pwsh-vault-cli ${VERSION}"
    echo ""
    echo "# Usage:"
    echo "  $ pwsh-vault-cli                      --> Run Main CLI"
    echo "  $ pwsh-vault-cli --export [--encrypt] --> Export Vault"
    echo "  $ pwsh-vault-cli --import <path-file> --> Import Vault"
    echo "  $ pwsh-vault-cli --gen-password [num] --> Generate password"
    echo "  $ pwsh-vault-cli --help               --> Show Help"
    echo ""
    exit
}

function size_extracted_vault_logins() {
  name_length=1
  name_count=1
  ls -1 ${pwsh_vault}/logins | while read entry ; do
    name_count=$(echo "logins/${entry}" | wc -m)
    # Compare the maximum size of the variables
    if [ ${name_count} -gt ${name_length} ] ; then
      name_length=${name_count}
      echo ${name_length}
    fi
  done
}

function size_extracted_vault_bcard() {
  name_length=1
  name_count=1
  ls -1 ${pwsh_vault}/bcard | while read entry ; do
    name_count=$(echo "bcard/${entry}" | wc -m)
    # Compare the maximum size of the variables
    if [ ${name_count} -gt ${name_length} ] ; then
      name_length=${name_count}
      echo ${name_length}
    fi
  done
}

function size_extracted_vault_notes() {
  name_length=1
  name_count=1
  ls -1 ${pwsh_vault}/notes | while read entry ; do
    name_count=$(echo "notes/${entry}" | wc -m)
    # Compare the maximum size of the variables
    if [ ${name_count} -gt ${name_length} ] ; then
      name_length=${name_count}
      echo ${name_length}
    fi
  done
}

function process_extracted_vault_logins() {
  name_length=$(size_extracted_vault_logins | tail -1)
  login_length="11"
  password_length="18"
  url_length="10"
  otp_length="10"
  count_length=1
  row_length=$(expr ${name_length} + ${login_length} + ${password_length} + ${url_length} + ${otp_length} + 10)
  row_length_show=1
  echo ""
  ls -1 ${pwsh_vault}/logins | while read entry ; do
    name="${entry}"
    login="Hidden User"
    password="Encrypted Password"
    url="Hidden URL"
    otp="Hidden OTP"
    name_count=$(echo "logins/${entry}" | wc -m)
    name_count=$(expr ${name_length} - ${name_count})
    echo -n " # logins/${name}"
    name_max=1
    while [ ${name_max} -le ${name_count} ] ; do
      echo -n " "
      name_max=$(expr ${name_max} + 1)
    done
    echo " # ${login} # ${password} # ${url} # ${otp} # "
  done
}

function process_extracted_vault_bcard() {
  name_length=$(size_extracted_vault_bcard | tail -1)
  owner_length="12"
  card_length="11"
  expiry_length="13"
  cvv_length="13"
  row_length=$(expr ${name_length} + ${owner_length} + ${card_length} + ${expiry_length} + ${cvv_length} + 10)
  row_length_show=1
  echo ""
  ls -1 ${pwsh_vault}/bcard | while read entry ; do
    name="${entry}"
    owner="Hidden Owner"
    card="Hidden Card"
    expiry="Hidden Expiry"
    cvv="Encrypted CVV"
    name_count=$(echo "bcard/${entry}" | wc -m)
    name_count=$(expr ${name_length} - ${name_count})
    echo -n " # bcard/${name}"
    name_max=1
    while [ ${name_max} -le ${name_count} ] ; do
      echo -n " "
      name_max=$(expr ${name_max} + 1)
    done
    echo " # ${owner} # ${card} # ${expiry} # ${cvv} # "
  done
}

function process_extracted_vault_notes() {
  name_length=$(size_extracted_vault_notes | tail -1)
  note_length="14"
  row_length=$(expr ${name_length} + ${note_length} + 4)
  row_length_show=1
  echo ""
  ls -1 ${pwsh_vault}/notes | while read entry ; do
    name="${entry}"
    note="Encrypted Note"
    name_count=$(echo "notes/${entry}" | wc -m)
    name_count=$(expr ${name_length} - ${name_count})
    echo -n " # notes/${name}"
    name_max=1
    while [ ${name_max} -le ${name_count} ] ; do
      echo -n " "
      name_max=$(expr ${name_max} + 1)
    done
    echo " # ${note} # "
  done
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
  clear
  cd ${pwsh_vault}
  echo ""
  echo "# pwsh-vault-cli ${VERSION}"
  echo ""
  echo "# Creating Vault List Entries:"
  list_logins_count=$(ls -1 logins/ | wc -l)
  list_bcard_count=$(ls -1 bcard/ | wc -l)
  list_notes_count=$(ls -1 notes/ | wc -l)
  if [ ${list_logins_count} -ne 0 ] ; then
    process_extracted_vault_logins
  fi
  cd ${pwsh_vault}
  if [ ${list_bcard_count} -ne 0 ] ; then
    process_extracted_vault_bcard
  fi
  cd ${pwsh_vault}
  if [ ${list_notes_count} -ne 0 ] ; then
    process_extracted_vault_notes
  fi
  echo ""
  echo -n "# Press enter key to continue " ; read enter_continue
}

function change_masterkey_vault() {
  clear
  load_masterkey=$(cat ${pwsh_vault_masterkey} | cut -d ";" -f 2)
  masterkey_loaded=$(vault_key_decrypt "${load_masterkey}")
  count_logins=$(ls -1 ${pwsh_vault}/logins/ | wc -l)
  count_notes=$(ls -1 ${pwsh_vault}/notes/ | wc -l)
  count_bcard=$(ls -1 ${pwsh_vault}/bcard/ | wc -l)
  echo ""
  echo "# pwsh-vault-cli ${VERSION}"
  echo ""
  echo -n "# Enter Current MasterKey: " ; read -s current_masterkey
  if [ "${current_masterkey}" == "${masterkey_loaded}" ] ; then
    echo ""
    echo -n "# Enter New MasterKey: " ; read -s masterkey_input
    echo ""
    echo -n "# Re-Enter New MasterKey: " ; read -s masterkey_reinput
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
      echo "# New MasterKey configuration finished"
      echo ""
      echo -n "# Press enter key to continue " ; read enter_continue
    else
      echo "" && echo ""
      echo "# Both passwords do not match"
      echo ""
      echo -n "# Press enter key to continue " ; read enter_continue
    fi
  else
    echo "" && echo ""
    echo "# Wrong MasterKey"
    echo ""
    echo -n "# Press enter key to continue " ; read enter_continue
  fi
}

function remove_entry_vault() {
  count_logins=$(ls -1 ${pwsh_vault}/logins/ | wc -l)
  count_notes=$(ls -1 ${pwsh_vault}/notes/ | wc -l)
  count_bcard=$(ls -1 ${pwsh_vault}/bcard/ | wc -l)
  count_total=$(expr ${count_logins} + ${count_notes} + ${count_bcard})
  clear
  echo ""
  echo "# pwsh-vault-cli ${VERSION}"
  echo ""
  echo "# Your Current Vault Entries: "
  echo ""
  if [ ${count_logins} -ne 0 ] ; then
    list_logins=$(ls -1 ${pwsh_vault}/logins/)
    for login in ${list_logins} ; do
      echo " * logins/${login}"
    done
  fi
  if [ ${count_notes} -ne 0 ] ; then
    list_notes=$(ls -1 ${pwsh_vault}/notes/)
    for note in ${list_notes} ; do
      echo " * notes/${note}"
    done
  fi
  if [ ${count_bcard} -ne 0 ] ; then
    list_bcard=$(ls -1 ${pwsh_vault}/bcard/)
    for card in ${list_bcard} ; do
      echo " * bcard/${card}"
    done
  fi
  if [ ${count_total} -ne 0 ] ; then
    echo ""
  fi
  echo -n "# Type entry to remove (Default: return): " ; read vault_remove_entry
  if [ -z "${vault_remove_entry}" ] ; then
    echo "# Canceled Remove Entry"
  else
    if [ -d "${pwsh_vault}/${vault_remove_entry}" ] ; then
      echo ""
      echo "# Selected Entry ${vault_remove_entry}"
      echo -n "# Are you sure? (Default: n) (y/n): " ; read are_you_sure
      if [ "${are_you_sure}" == "y" ] ; then
        rm -rf "${pwsh_vault}/${vault_remove_entry}"
        echo ""
        echo "# Entry ${vault_remove_entry} Removed"
        echo ""
        echo -n "# Press enter key to continue " ; read enter_continue
      fi
    else
      echo ""
      echo "# Entry ${vault_remove_entry} does no exist"
      echo ""
      echo -n "# Press enter key to continue " ; read enter_continue
    fi
  fi
}

function edit_entry_vault() {
  count_logins=$(ls -1 ${pwsh_vault}/logins/ | wc -l)
  count_notes=$(ls -1 ${pwsh_vault}/notes/ | wc -l)
  count_bcard=$(ls -1 ${pwsh_vault}/bcard/ | wc -l)
  count_total=$(expr ${count_logins} + ${count_notes} + ${count_bcard})
  clear
  echo ""
  echo "# pwsh-vault-cli ${VERSION}"
  echo ""
  echo "# Your Current Vault Entries: "
  echo ""
  if [ ${count_logins} -ne 0 ] ; then
    list_logins=$(ls -1 ${pwsh_vault}/logins/)
    for login in ${list_logins} ; do
      echo " * logins/${login}"
    done
  fi
  if [ ${count_notes} -ne 0 ] ; then
    list_notes=$(ls -1 ${pwsh_vault}/notes/)
    for note in ${list_notes} ; do
      echo " * notes/${note}"
    done
  fi
  if [ ${count_bcard} -ne 0 ] ; then
    list_bcard=$(ls -1 ${pwsh_vault}/bcard/)
    for card in ${list_bcard} ; do
      echo " * bcard/${card}"
    done
  fi
  if [ ${count_total} -ne 0 ] ; then
    echo ""
  fi
  echo -n "# Type entry to edit (Default: return): " ; read vault_edit_entry
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
        echo -n "# Enter Username (Default: ${read_userame_dc}): " ; read name_username
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
        echo -n "# Enter Password (Default: ${read_password_dc}): " ; read name_password
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
        echo -n "# Enter URL (Default: ${read_url_dc}): " ; read name_url
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
        echo -n "# Enter OTP (Default: ${read_otp_dc}): " ; read name_otp
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
        echo -n "# Enter Owner (Default: ${read_owner_dc}): " ; read name_owner
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
        echo -n "# Enter Card Number (Default: ${read_card_dc}): " ; read name_card
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
        echo -n "# Enter Expiry Date (Default: ${read_expiry_dc}): " ; read name_expiry
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
        echo -n "# Enter CVV (Default: ${read_cvv_dc}): " ; read name_cvv
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
        echo -n "# Enter Note (Default: ${read_note_dc}): " ; read name_note
        if [ ! -z "${name_note}" ] ; then
          name_note=$(removeSpaces "${name_note}")
          name_note=$(vault_key_encrypt "${name_note}")
          note_text=$(vault_key_encrypt "note")
          echo "${masterkey_load}" > "${pwsh_vault}/${vault_edit_entry}/note"
          echo "${note_text};${name_note}" >> "${pwsh_vault}/${vault_edit_entry}/note"
        fi
      fi
      echo ""
      echo "# ENTRY ${vault_edit_entry} EDITED"
      echo ""
      echo -n "# Press enter key to continue " ; read enter_continue
    else
      echo ""
      echo "# Entry ${vault_edit_entry} does no exist"
      echo ""
      echo -n "# Press enter key to continue " ; read enter_continue
    fi
  fi
}

function search_entries_vault() {
  clear
  cd ${pwsh_vault}
  echo ""
  echo "# pwsh-vault-cli ${VERSION}"
  echo ""
  echo "# Preparing Vault List Entries:"
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
    username_show="Hidden User"
    password_show="Encrypted Password"
    url_show="Hidden URL"
    otp_show="Hidden OTP"
    for login in ${list_logins} ; do
      echo "logins/${login},${username_show},${password_show},${url_show},${otp_show}" >> ${pwsh_vault_cache_logins_otp}
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
  echo " l --> Search Login/Website Entry"
  echo " o --> Search Login/Website Entry (Show OTP)"
  echo " b --> Search Credit/Bank Card Entry"
  echo " n --> Search Note Entry"
  echo ""
  echo " r --> Back"
  echo ""
  echo -n "# Type an option (Default: r): " ; read search_entry
  if [ "${search_entry}" == "l" ] ; then
    echo ""
    echo -n "# Type a string to search: " ; read string_search
    echo ""
    if [ -z "${string_search}" ] ; then
      rm -rf ${pwsh_vault_cache_temp}
      touch ${pwsh_vault_cache_temp}
      touch ${pwsh_vault_cache_logins}
      cat ${pwsh_vault_cache_logins} > ${pwsh_vault_cache_temp}
      cat ${pwsh_vault_cache_temp} > ${pwsh_vault_cache_logins}
      lines_read=$(cat ${pwsh_vault_cache_logins} 2> /dev/null | wc -l)
      if [ ${lines_read} -eq 0 ] ; then
        echo "# No Entries to Show"
        echo ""
        echo -n "# Press enter key to continue " ; read enter_continue
      else
        count=1
        for show in $(cat ${pwsh_vault_cache_logins} | cut -d "," -f 1) ; do
          echo " ${count} --> ${show},${username_show},${password_show},${url_show},${otp_show}"
          count=$(expr ${count} + 1)
        done
        echo ""
        echo " b --> Back"
        echo ""
        search_show_entry=""
        while [ "${search_show_entry}" != "b" ] ; do
          echo -n "# Type number entry to show content (1-XXX or b): " ; read search_show_entry
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
            echo ""
            echo "* Name Entry: logins/${result}"
            echo "* Login: ${username_decrypt}"
            echo "* Password: ${password_decrypt}"
            echo "* URL: ${url_decrypt}"
            echo "* OTP: ${otp_decrypt}"
            echo ""
          else
            echo ""
            echo "# Entry logins/${result} CORRUPTED"
            echo ""
          fi
        done
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
        echo "# No Entries to Show"
        echo ""
        echo -n "# Press enter key to continue " ; read enter_continue
      else
        count=1
        for show in $(cat ${pwsh_vault_cache_logins} | cut -d "," -f 1) ; do
          echo " ${count} --> ${show},${username_show},${password_show},${url_show},${otp_show}"
          count=$(expr ${count} + 1)
        done
        echo ""
        echo " b --> Back"
        echo ""
        search_show_entry=""
        while [ "${search_show_entry}" != "b" ] ; do
          echo -n "# Type number entry to show content (1-XXX or b): " ; read search_show_entry
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
            echo ""
            echo "* Name Entry: logins/${result}"
            echo "* Login: ${username_decrypt}"
            echo "* Password: ${password_decrypt}"
            echo "* URL: ${url_decrypt}"
            echo "* OTP: ${otp_decrypt}"
            echo ""
          else
            echo ""
            echo "# Entry logins/${result} CORRUPTED"
            echo ""
          fi
        done
      fi
      rm -rf ${pwsh_vault_cache_logins}
      search_entries_vault
    fi
  elif [ "${search_entry}" == "o" ] ; then
    echo ""
    echo -n "# Type a string to search: " ; read string_search
    echo ""
    if [ -z "${string_search}" ] ; then
      rm -rf ${pwsh_vault_cache_temp}
      touch ${pwsh_vault_cache_temp}
      touch ${pwsh_vault_cache_logins}
      touch ${pwsh_vault_cache_logins_otp}
      cat ${pwsh_vault_cache_logins_otp} >> ${pwsh_vault_cache_temp}
      cat ${pwsh_vault_cache_temp} > ${pwsh_vault_cache_logins}
      lines_read=$(cat ${pwsh_vault_cache_logins} 2> /dev/null | wc -l)
      if [ ${lines_read} -eq 0 ] ; then
        echo "# No Entries to Show"
        echo ""
        echo -n "# Press enter key to continue " ; read enter_continue
      else
        count=1
        for show in $(cat ${pwsh_vault_cache_logins} | cut -d "," -f 1) ; do
          echo " ${count} --> ${show},${username_show},${password_show},${url_show},${otp_show}"
          count=$(expr ${count} + 1)
        done
        echo ""
        echo "b --> Back"
        echo ""
        search_show_entry=""
        while [ "${search_show_entry}" != "b" ] ; do
          echo -n "# Type number entry to show content (1-XXX or b): " ; read search_show_entry
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
            echo ""
            echo "* Name Entry: logins/${result}"
            echo "* Login: ${username_decrypt}"
            echo "* Password: ${password_decrypt}"
            echo "* URL: ${url_decrypt}"
            echo "* OTP: ${otp_decrypt}"
            echo ""
          else
            echo ""
            echo "# Entry logins/${result} CORRUPTED"
            echo ""
          fi
        done
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
        echo "# No Entries to Show"
        echo ""
        echo -n "# Press enter key to continue " ; read enter_continue
      else
        count=1
        for show in $(cat ${pwsh_vault_cache_logins} | cut -d "," -f 1) ; do
          echo " ${count} --> ${show},${username_show},${password_show},${url_show},${otp_show}"
          count=$(expr ${count} + 1)
        done
        echo ""
        echo " b --> Back"
        echo ""
        search_show_entry=""
        while [ "${search_show_entry}" != "b" ] ; do
          echo -n "# Type number entry to show content (1-XXX or b): " ; read search_show_entry
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
            echo ""
            echo "* Name Entry: logins/${result}"
            echo "* Login: ${username_decrypt}"
            echo "* Password: ${password_decrypt}"
            echo "* URL: ${url_decrypt}"
            echo "* OTP: ${otp_decrypt}"
            echo ""
          else
            echo ""
            echo "# Entry logins/${result} CORRUPTED"
            echo ""
          fi
        done
      fi
      rm -rf ${pwsh_vault_cache_logins}
      rm -rf ${pwsh_vault_cache_logins_otp}
      search_entries_vault
    fi
  elif [ "${search_entry}" == "b" ] ; then
    echo ""
    echo -n "# Type a string to search: " ; read string_search
    echo ""
    if [ -z "${string_search}" ] ; then
      rm -rf ${pwsh_vault_cache_temp}
      touch ${pwsh_vault_cache_temp}
      touch ${pwsh_vault_cache_bcard}
      cat ${pwsh_vault_cache_bcard} >> ${pwsh_vault_cache_temp}
      cat ${pwsh_vault_cache_temp} > ${pwsh_vault_cache_bcard}
      lines_read=$(cat ${pwsh_vault_cache_bcard} 2> /dev/null | wc -l)
      if [ ${lines_read} -eq 0 ] ; then
        echo "# No Entries to Show"
        echo ""
        echo -n "# Press enter key to continue " ; read enter_continue
      else
        count=1
        for show in $(cat ${pwsh_vault_cache_bcard} | cut -d "," -f 1) ; do
          echo " ${count} --> ${show},${owner_show},${num_card_show},${expiry_show},${cvv_show}"
          count=$(expr ${count} + 1)
        done
        echo ""
        echo " b --> Back"
        echo ""
        search_show_entry=""
        while [ "${search_show_entry}" != "b" ] ; do
          echo -n "# Type number entry to show content (1-XXX or b): " ; read search_show_entry
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
            echo ""
            echo "* Name Entry: bcard/${result}"
            echo "* Owner: ${owner_decrypt}"
            echo "* Card: ${card_decrypt}"
            echo "* Expiry: ${expiry_decrypt}"
            echo "* CVV: ${cvv_decrypt}"
            echo ""
          else
            echo ""
            echo "# Entry bcard/${result} CORRUPTED"
            echo ""
          fi
        done
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
        echo "# No Entries to Show"
        echo ""
        echo -n "# Press enter key to continue " ; read enter_continue
      else
        count=1
        for show in $(cat ${pwsh_vault_cache_bcard} | cut -d "," -f 1) ; do
          echo " ${count} --> ${show},${owner_show},${num_card_show},${expiry_show},${cvv_show}"
          count=$(expr ${count} + 1)
        done
        echo ""
        echo " b --> Back"
        echo ""
        search_show_entry=""
        while [ "${search_show_entry}" != "b" ] ; do
          echo -n "# Type number entry to show content (1-XXX or b): " ; read search_show_entry
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
            echo ""
            echo "* Name Entry: bcard/${result}"
            echo "* Owner: ${owner_decrypt}"
            echo "* Card: ${card_decrypt}"
            echo "* Expiry: ${expiry_decrypt}"
            echo "* CVV: ${cvv_decrypt}"
            echo ""
          else
            echo ""
            echo "# Entry bcard/${result} CORRUPTED"
            echo ""
          fi
        done
      fi
      rm -rf ${pwsh_vault_cache_bcard}
      search_entries_vault
    fi
  elif [ "${search_entry}" == "n" ] ; then
    echo ""
    echo -n "# Type a string to search: " ; read string_search
    echo ""
    if [ -z "${string_search}" ] ; then
      rm -rf ${pwsh_vault_cache_temp}
      touch ${pwsh_vault_cache_temp}
      touch ${pwsh_vault_cache_notes}
      cat ${pwsh_vault_cache_notes} >> ${pwsh_vault_cache_temp}
      cat ${pwsh_vault_cache_temp} > ${pwsh_vault_cache_notes}
      lines_read=$(cat ${pwsh_vault_cache_notes} 2> /dev/null | wc -l)
      if [ ${lines_read} -eq 0 ] ; then
        echo "# No Entries to Show"
        echo ""
        echo -n "# Press enter key to continue " ; read enter_continue
      else
        count=1
        for show in $(cat ${pwsh_vault_cache_notes} | cut -d "," -f 1) ; do
          echo " ${count} --> ${show},${note_show}"
          count=$(expr ${count} + 1)
        done
        echo ""
        echo " b --> Back"
        echo ""
        search_show_entry=""
        while [ "${search_show_entry}" != "b" ] ; do
          echo -n "# Type number entry to show content (1-XXX or b): " ; read search_show_entry
          result=$(cat ${pwsh_vault_cache_notes} | head -${search_show_entry} 2>/dev/null | tail -1 | cut -d "," -f 1 | cut -d "/" -f 2)
          corrupted_result=$(check_corrupted_entry_vault ${result} notes)
          if [ ${corrupted_result} -eq 0 ] ; then
            note_decrypt=$(cat notes/${result}/note | tail -1 | cut -d ";" -f 2)
            note_decrypt=$(vault_key_decrypt "${note_decrypt}")
            note_decrypt=$(restoreSpaces "${note_decrypt}")
            echo ""
            echo "* Name Entry: notes/${result}"
            echo "* Note: ${note_decrypt}"
            echo ""
          else
            echo ""
            echo "# Entry notes/${result} CORRUPTED"
            echo ""
          fi
        done
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
        echo "# No Entries to Show"
        echo ""
        echo -n "# Press enter key to continue " ; read enter_continue
      else
        count=1
        for show in $(cat ${pwsh_vault_cache_notes} | cut -d "," -f 1) ; do
          echo " ${count} --> ${show},${note_show}"
          count=$(expr ${count} + 1)
        done
        echo ""
        echo " b --> Back"
        echo ""
        search_show_entry=""
        while [ "${search_show_entry}" != "b" ] ; do
          echo -n "# Type number entry to show content (1-XXX or b): " ; read search_show_entry
          result=$(cat ${pwsh_vault_cache_notes} | head -${search_show_entry} 2>/dev/null | tail -1 | cut -d "," -f 1 | cut -d "/" -f 2)
          corrupted_result=$(check_corrupted_entry_vault ${result} notes)
          if [ ${corrupted_result} -eq 0 ] ; then
            note_decrypt=$(cat notes/${result}/note | tail -1 | cut -d ";" -f 2)
            note_decrypt=$(vault_key_decrypt "${note_decrypt}")
            note_decrypt=$(restoreSpaces "${note_decrypt}")
            echo ""
            echo "* Name Entry: notes/${result}"
            echo "* Note: ${note_decrypt}"
            echo ""
          else
            echo ""
            echo "# Entry notes/${result} CORRUPTED"
            echo ""
          fi
        done
      fi
      rm -rf ${pwsh_vault_cache_notes}
      search_entries_vault
    fi
  else
    echo > /dev/null
  fi
}

function pwsh_vault_main() {
  vault_main_init=0
  while [ ${vault_main_init} -eq 0 ] ;do
    clear
    echo ""
    echo "# pwsh-vault-cli ${VERSION}"
    echo ""
    echo " c --> Create Entry"
    echo " e --> Edit Entry"
    echo " s --> Search Entry"
    echo " l --> List Entries"
    echo " r --> Remove Entry"
    echo " m --> Change MasterKey"
    echo " g --> Generate Password"
    echo " x --> Export Vault"
    echo " i --> Import Vault"
    echo ""
    echo " a --> About"
    echo " q --> Quit"
    echo ""
    echo -n "# Type an option: " ; read vault_main_option
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

