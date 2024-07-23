#!/bin/bash

log_file="${1}"
lines="${2}"
entity_key="${3}"
pattern="${4}"

capt_groups=0

if [[ $(which perl &>/dev/null; echo $?) -ne 0 ]]; then
  echo "Error: perl not found, please install it! Exiting..."
  exit 1
fi



function get_json_header () {
  echo "["
}

function get_json_body_line () {
  # $1 ... - entity name

  local result
  local i

  i=1

  [[ ${capt_groups} -eq 0 ]] && capt_groups=$#

  result="{"

  if [[ ${capt_groups} -gt 1 ]]; then
  
    for entity in "$@"; do
      result="${result}\"{#${entity_key}_${i}}\":\"${entity}\","
      i=$((i+1))
    done
	
  else
    result="${result}\"{#${entity_key}}\":\"${1}\","
  fi

  result="${result%,*}},"

  echo "${result}"
}

function get_json_footer () {
  echo "]"
}



result="$(get_json_header)"

while read line; do

  [[ ${line} == "" ]] && continue

  result="${result}$(get_json_body_line ${line})"

done <<< "$(tail -${lines} "${log_file}" | grep -Po "${pattern}" | perl -ne 'while ($_ =~ /'"${pattern}"'/g) { print join(" ", map { $_ // "" } ($1, $2, $3, $4, $5, $6, $7, $8, $9)), "\n"; }' | sort -u)"

result="${result%,*}"

result="${result}$(get_json_footer)"

echo "${result}"

exit 0
