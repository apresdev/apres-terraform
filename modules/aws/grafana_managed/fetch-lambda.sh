#!/usr/bin/env bash

# Parse the command line arguments
binary_path=$1
asset_url=$2
version=$3

function log {
    echo "$(date +'%Y-%m-%dT%H:%M:%S') $1" >> fetch-lambda.log
}

log "Fetching the latest binary from $asset_url, version $version to $binary_path"

# Remove any existing binaries
rm -f ${binary_path}

# Download the latest binary
curl -LJ \
    -o ${binary_path} \
    --create-dirs \
    -H "Authorization: Bearer $GITHUB_TOKEN" \
    -H "Accept: application/octet-stream" \
    ${asset_url}  > /dev/null 2> /dev/null

retval=$?
if [ ${retval} -ne 0 ]; then
    log "Failed to download the binary: ${retval}"
    echo '{ "download": "false", "md5sum": "" }'
    exit ${retval}
fi

# Save the current md5sum
md5=`md5sum ${binary_path} | awk '{print $1}'`
retval=$?
if [ ${retval} -ne 0 ]; then
    log "Failed to calculate the md5sum of ${binary_path}: ${retval}"
    echo '{ "download": "false", "md5sum": "" }'
    exit ${retval}
fi
log "Downloaded binary ${binary_path} with md5sum: ${md5}"

# Return a JSON result, needed for the "external" terraform resource
echo '{ "download": "true", "md5sum": "'$md5'" }'
exit 0
