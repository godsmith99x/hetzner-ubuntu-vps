#!/usr/bin/bash --

prog=$(basename $0)

function usage() {
    echo "Usage: $prog <help|create|delete|status>"
    echo '    help        Display this usage message.'
    echo '    create      Create an ubuntu vps with required resources.'
    echo '    delete      Delete all the currently running vps in the project.'
    echo '    status      List all resources in the project.'
    return 0
}

# Check if hcloud is installed
if ! command -v hcloud &> /dev/null; then
    echo "Error: hcloud command not found. Please install hcloud CLI tool."
    exit 1
fi

# Source the environment variables
if [ -f .env ]; then
    source .env
else
    echo "Please create a .env file with the required environment variables"
    exit 1
fi

# Verify SSH key exists in hcloud
if ! hcloud ssh-key list -o noheader -o columns=name | grep -qF "$SSH_KEY"; then
    echo "Error: SSH key '$SSH_KEY' not found in hcloud."
    echo "Available SSH keys:"
    hcloud ssh-key list -o columns=name
    exit 1
fi

# Create a VPS server
function create_vps() {
    echo "Creating a VPS server with the following parameters:"
    echo "Server Name: $SERVER_NAME"
    echo "Server Type: $SERVER_TYPE"
    echo "Server Image: $SERVER_IMAGE"
    echo "Server Location: $SERVER_LOCATION"
    echo "SSH Key: $SSH_KEY"

    hcloud server create \
        --name "$SERVER_NAME" \
        --type "$SERVER_TYPE" \
        --image "$SERVER_IMAGE" \
        --location "$SERVER_LOCATION" \
        --ssh-key "$SSH_KEY" \
        --without-ipv6 \
        --user-data-from-file cloud-init.yaml
}

function delete_vps() {
    hcloud server list -o noheader -o columns=name | xargs -I {} hcloud server delete {}
}

function get_status() {
    hcloud server list
}

case "$1" in
help)
    usage
    ;;
create)
    create_vps
    ;;
delete)
    delete_vps
    ;;
status)
    get_status
    #always return success
    exit 0
    ;;
*)
    usage
    ;;
esac

exit $?
