#!/bin/bash

log_file="${1}"
lines="${2}"
entity_key="${3}"
pattern="${4}"
group_by="${5}"

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

# extract "group by"
# group by as many criterias as there are capturing groups
# say you have 3 capturing groups
# this parameter should come in manner cg1_regex1;cg2_regex1|cg2_regex2;cg3_regex1|cg3_regex2|cg3_regex3
# cg_ stands for capturing group
# e.g. "\d{3};.*account.*|.*customer.*;.*error.*|.*warning.*|.*critical.*"

oldIFS=$IFS
IFS=";"
group_by=($group_by)
IFS=$oldIFS

i=0

while read line; do

  [[ ${line} == "" ]] && continue

  [[ ${capt_groups} -eq 0 ]] && capt_groups=$(awk '{print NF}' <<< "${line}")

  if [[ "${#group_by[@]}" -ne 0 ]]; then

    match=""
    j=0
    line=($line)

    while [[ $j -lt $capt_groups ]]; do

      cg_match="${line[${j}]}"

      # add grouping...
      # if nothing to add - continue

      [[ $(grep -Pc "${group_by[${j}]}" <<< "${cg_match}") -eq 0 ]] && continue 2
 
      oldIFS=$IFS
      IFS="|"
      cg_regex=(${group_by[${j}]})
      IFS=$oldIFS

      if [[ "${#cg_regex[@]}" -eq 0 ]]; then
        match="${match} ${cg_match}"
      fi

      for this_regex in "${cg_regex[@]}"; do
 
        if [[ $(grep -Pc "${this_regex}" <<< "${cg_match}") -ne 0 ]]; then
          this_regex=$(echo "${this_regex}" | sed -e 's/\\/\\\\/g')
          match="${match} ${this_regex}"
          break
        fi

      done

      j=$((j+1))

    done

    [[ " ${matches[*]} " == *" ${match} "* ]] && continue

    matches[$i]=${match}

    i=$((i+1))

    result="${result}$(get_json_body_line ${match})"

  else
    result="${result}$(get_json_body_line ${line})"
  fi

done <<< "$(tail -${lines} "${log_file}" | grep -Po "${pattern}" | perl -ne 'while ($_ =~ /'"${pattern}"'/g) { print join(" ", map { $_ // "" } ($1, $2, $3, $4, $5, $6, $7, $8, $9)), "\n"; }' | sort -u)"

result="${result%,*}"

result="${result}$(get_json_footer)"

echo "${result}"

exit 0
