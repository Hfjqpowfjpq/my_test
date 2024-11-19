#!/bin/bash

set -eu
set -o pipefail

# Necessay to call functions defined
PARENT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TENKS_PATH="/root/my_test/tenks" # Hard coded shouldn't be tho
SEED_IP="192.168.33.5"
TENKS_CONFIG="$PARENT/tenks.yml"

# Configuration
function write_bifrost_clouds_yaml {
    # Pull clouds.yaml from Bifrost container and change certificate path.
    if [[ ! -f ~/.config/openstack/clouds.yaml ]]; then
        mkdir -p ~/.config/openstack
        scp stack@$SEED_IP:/home/stack/.config/openstack/clouds.yaml ~/.config/openstack/clouds.yaml
        sed -i 's|/home/stack/.config/openstack/bifrost.crt|~/.config/openstack/bifrost.crt|g' ~/.config/openstack/clouds.yaml
    else
        echo "Not updating clouds.yaml file because it already exists at $HOME/.config/openstack/clouds.yaml. Try removing it if authentication against Bifrost fails."
    fi
    #Pull Bifrost PEM certificate from seed.
    if [[ ! -f ~/.config/openstack/bifrost.crt ]]; then
        mkdir -p ~/.config/openstack
        scp stack@$SEED_IP:/home/stack/.config/openstack/bifrost.crt ~/.config/openstack/bifrost.crt
    else
        echo "Not updating Bifrost certificate file because it already exists at $HOME/.config/openstack/bifrost.crt. Try removing it if authentication against Bifrost fails."
    fi
}

function run_tenks_playbook {
    # Run a Tenks playbook. Arguments:
    # $1: The path to the Tenks repo.
    # $2: The name of the playbook to run.
    local TENKS_PATH="$1"
    local TENKS_PLAYBOOK="$2"
    local TENKS_DEPLOY_TYPE="${3:-default}"

    if [[ "${TENKS_DEPLOY_TYPE}" = "default" || # This is our base configuration
               "${TENKS_DEPLOY_TYPE}" = "overcloud" ]]; then

        write_bifrost_clouds_yaml
        export OS_CLOUD=bifrost

    else
        die $LINENO "Bad TENKS_DEPLOY_TYPE: ${TENKS_DEPLOY_TYPE}"
        exit 1
    fi

    ansible-playbook \
        -vvv \
        --inventory "$TENKS_PATH/ansible/inventory" \
        --extra-vars=@"$TENKS_CONFIG" \
        "$TENKS_PATH/ansible/$TENKS_PLAYBOOK"
}

function main {
    set -eu
    # Create a simple test Tenks deployment. Assumes that a bridge named
    # 'breth1' exists.  Arguments:
    echo "Configuring Tenks"

    source /root/my_test/venvs/tenks/bin/activate # Activate env

    # Install a trivial script for ovs-vsctl that talks to containerised OpenvSwitch.
    sudo cp --no-clobber "$PARENT/ovs-vsctl" /usr/bin/ovs-vsctl

    run_tenks_playbook "$TENKS_PATH" deploy.yml overcloud
}

main "$@"