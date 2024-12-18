#!/usr/bin/env bash

echo "INSTALL_PACKAGES: ${INSTALL_PACKAGES}"
for PACKAGE in "${INSTALL_PACKAGES}"; do
  echo "Installing $PACKAGE"
  yum install -y $PACKAGE
done