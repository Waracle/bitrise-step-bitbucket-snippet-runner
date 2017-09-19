#!/usr/bin/env bash
set -e
set -o pipefail

if [[ "${is_debug}" == 'yes' ]]; then
	set -x
fi

echo
echo "script_url: ${script_url}"

# Required input validation
if [[ "${script_url}" == "" ]]; then
	echo
	echo "No script_url provided as environment variable. Terminating..."
	echo
	exit 1
fi

echo
echo "working_dir: ${working_dir}"

if [ ! -z "${working_dir}" ] ; then
	echo "==> Switching to working directory: ${working_dir}"
	cd "${working_dir}"
	if [ $? -ne 0 ] ; then
		echo " [!] Failed to switch to working directory: ${working_dir}"
		exit 1
	fi
fi


echo
echo "---------------------------------------------------"
echo "--- Executing script: ${script_url}"
echo

# https://stackoverflow.com/a/26766402/1037989
# ^(([^:/?#]+):)?(//([^/?#]*))?([^?#]*)(\?([^#]*))?(#(.*))?
#  12            3  4          5       6  7        8 9
REGEX='^(([^:/?#]+):)?(//([^/?#]*))?([^?#]*)(\?([^#]*))?(#(.*))?'

if [[ $script_url =~ $REGEX ]]; then
 PROTOCOL="${BASH_REMATCH[2]}" 
 DOMAIN="${BASH_REMATCH[4]}" 
 SNIPPET="${BASH_REMATCH[5]}" 
fi

if [[ "$DOMAIN" == 'bitbucket.org' ]]; then
	HOST='api.bitbucket.org'
else
	HOST="${DOMAIN}/api"	 
fi

# inject username and password into the snippet url if required
if [[ ! -z "${username}" ]]; then
	HOST="${username}:${password}@${HOST}" 
fi

URL="${PROTOCOL}://${HOST}/2.0${SNIPPET}"

# get the snippet metadata and extract the correct url to download the file with
DOWNLOAD_URL="$(curl -sSL $URL | jq -r .files[].links.self.href)" 

# inject username and password into the download url if required
if [ ! -z "${username}" ]; then
	DOWNLOAD_URL="$(echo ${DOWNLOAD_URL} | sed "s|://|://$username:$password@|g")"
fi

# download the snippet file, and run the script
curl -sSl $DOWNLOAD_URL | bash

res_code=$?
if [ ${res_code} -ne 0 ] ; then
	echo "--- [!] The script returned with an error code: ${res_code}"
	echo "---------------------------------------------------"
	exit 1
fi

echo
echo "--- Script returned with a success code - OK"
echo "---------------------------------------------------"
exit 0
