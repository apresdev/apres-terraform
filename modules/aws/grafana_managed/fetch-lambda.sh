#!/bin/bash

# Parse the command line arguments
binary_path=$1
asset_url=$2
version=$3

# Determine the path to the version and md5sum files
version_file=`dirname $binary_path`/version.txt
md5sum_file="${binary_path}.md5sum"

download() {
    # Remove any existing binaries
    rm -f ${binary_path}

    # Download the latest binary
    curl -LJ \
        -o ${binary_path} \
        --create-dirs \
        -H "Authorization: Bearer $GITHUB_TOKEN" \
        -H "Accept: application/octet-stream" \
        ${asset_url}  > /dev/null 2> /dev/null

    # Save the current version
    echo $version > $version_file

    # Save the current md5sum
    md5sum ${binary_path} > $md5sum_file

    echo '{ "download": "true" }'
    exit 0
}

if [ -f $version_file ] && [ -f $md5sum_file ] && [ -f $binary_path ]; then
    current_version=`cat $version_file`
    if [ "$current_version" != "$version" ]; then
        download
    fi

    md5sum -c $md5sum_file > /dev/null 2> /dev/null
    if [ $? -ne 0 ]; then
        download
    fi
else
    download
fi

# Return a JSON result, needed for the "external" terraform resource
echo '{ "download": "false" }'

exit 0
