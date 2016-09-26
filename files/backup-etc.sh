#!/bin/bash
set -e

###### Variables ######################################################
dest_folder=/var/backups/system

###### Code ###########################################################

include_path(){
	# Recursive print folder path: ie "include_path /a/b/c 1" returns:
	# + /a/
	# + /a/b/
	# + /a/b/c/***
	if [[ ! "${1}" = "/" ]]
	then
		down_path="$(echo "$1" | sed 's;/[^/]*$;;')"
		[[ "${down_path}" = "" ]] && down_path="/" || true
		path="$(include_path "${down_path}" 0)"
		[[ "${path}" != "" ]] && echo "${path}"
		if [[ "${2}" -eq 1 ]]
		then
			echo "+ ${1}/***"
		else
			echo "+ ${1}/"
		fi
	fi
}

# Paths to backup specified in file "${1}"

if [[ -f "${1}" && -r "${1}" ]]
then
	readarray -t backup_folders < "${1}"
else
	echo "Specify input file"
	exit 1
fi

if [[ -n "${2}" ]]
then
	retain="${2}"
else
	echo "Specify days to retain"
	exit 1
fi

[[ ${retain} -gt 0 ]] || exit 1

# Add specified folders that exist to a list
for (( i=0; i<${#backup_folders[@]}; i++ ))
do
	[[ ! -d "${backup_folders[$i]}" ]] || folders[${#folders[@]}]="${backup_folders[$i]}"
done

# Exit if list of existing folders is empty
if [[ "${#folders[@]}" -eq 0 ]]
then
	echo "Not found any of the specified folders" 
	exit 1
fi

# Create destination folder if it does not exist
[[ ! -d "${dest_folder}" ]] && mkdir -p "${dest_folder}"

# Remove backups greater or equal to $retain
find "${dest_folder}" -maxdepth 1 -type d | while read line
do
	name="$(basename "${line}")"
	[[ "${name}" -lt "${retain}" ]] || rm -rf "${dest_folder}/${name}"
done

# Rotate backups
for (( i="$(( ${retain} - 1 ))"; i>0; i--))
do
	next="$(( ${i} + 1 ))"
	[[ -d "${dest_folder}/${i}" ]] && mv "${dest_folder}/${i}" "${dest_folder}/${next}" || true
done

include_file="$(mktemp -p /tmp "$(basename "$0").XXXXX")"

# Generate exclude file
for (( i=0; i<${#folders[@]}; i++ ))
do
	include_path "${folders[$i]}" 1 >> "${include_file}"
done
echo "- /***" >> "${include_file}"

if [[ -d "${dest_folder}/2" ]]
then
	rsync -aHx --exclude-from="${include_file}" / "${dest_folder}/1/" --link-dest="${dest_folder}/2"
else
	rsync -aHx --exclude-from="${include_file}" / "${dest_folder}/1/"
fi

rm "${include_file}"
