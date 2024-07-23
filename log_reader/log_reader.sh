#!/bin/bash

my_log="${1}"
skip="${2}"
skip_time="${3}"

[[ "${my_log}" == "" || ! -f "${my_log}" ]] && exit 1

log_read=$(dirname "${0}")/.$(basename "${my_log}").${skip}.read

# get current file size in bytes

current_size=$(wc -c < "${my_log}")

# remember how many bytes you have now for next read
# when run for first time, you don't know the previous

[[ ! -f "${log_read}" ]] && echo "${current_size}" > "${log_read}"

# if not ran for a while, consider you want to skip to fresh data

if [[ "${skip}" == "skip" && $(($(date +%s)-$(stat -c %Y "${log_read}"))) -gt "${skip_time}" ]]; then
  echo "${current_size}" > "${log_read}"
fi

bytes_read=$(cat "${log_read}")
echo "${current_size}" > "${log_read}"

# if rotated, let's read from the beginning

[[ ${bytes_read} -gt ${current_size} ]] && bytes_read=0

# get the portion

tail -c +$((bytes_read+1)) "${my_log}" | head -c $((current_size-bytes_read))

exit 0
