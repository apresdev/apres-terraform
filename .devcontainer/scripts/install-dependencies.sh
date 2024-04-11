#!/usr/bin/env bash
IAMLIVE_VERSION=v1.1.8
IAMLIVE_ARCH=arm64

ARCHIVE_FILE=iamlive-${IAMLIVE_VERSION}-linux-${IAMLIVE_ARCH}.tar.gz
wget https://github.com/iann0036/iamlive/releases/download/${IAMLIVE_VERSION}/${ARCHIVE_FILE}
tar xzvf ${ARCHIVE_FILE}
sudo mv iamlive /usr/local/bin
rm ${ARCHIVE_FILE}