#!/bin/bash

set -eu
set -o pipefail

# Simple script to configure and deploy a Tenks cluster. This should be
# executed from within the VM. Arguments:
# $1: The path to the Tenks repo.

# Necessay to call functions defined
PARENT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${PARENT}/functions"
TENKS_PATH="root/my_test/tenks" # Hard coded shouldn't be tho

function main {
    tenks_deploy "$TENKS_PATH" overcloud
}

main "$@"