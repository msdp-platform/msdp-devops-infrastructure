#!/bin/bash
# Cleanup duplicate network files
rm -f network-auto.tf
rm -f network-smart.tf
rm -rf modules/network-resolver
echo "Cleaned up duplicate network files"