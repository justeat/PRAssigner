#!/bin/bash
set -e

COMPONENT_NAME="PR Assigner"
DOCKER_IMAGE_NAME="pr_assigner"

print_helper() {
    echo """
Usage: \"$0 <command>\"

Commands:
    - ship         Build \"$COMPONENT_NAME\" and deploy and related infrastructure
    - destroy      Destroy \"$COMPONENT_NAME\" related infrastructure

"""
}

build_docker_image() {
    docker build . -t $DOCKER_IMAGE_NAME
}

build_and_deploy() {
    docker run \
        --rm \
        -e AWS_DEFAULT_REGION=$AWS_DEFAULT_REGION \
        -e AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY \
        -e AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID \
        -v "$(pwd)":/workspace \
        -w /workspace $DOCKER_IMAGE_NAME \
        bash -cl "./scripts/deploy.sh"
}

destroy() {
    docker run \
        --rm \
        -e AWS_DEFAULT_REGION=$AWS_DEFAULT_REGION \
        -e AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY \
        -e AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID \
        -v "$(pwd)":/workspace \
        -w /workspace $DOCKER_IMAGE_NAME \
        bash -cl "./scripts/destroy.sh"
}

main() {
    source .credz

    if [[ $1 == "ship" ]]; then
        build_docker_image
        build_and_deploy
    elif [[ $1 == "destroy" ]]; then
        build_docker_image
        destroy
    else
        print_helper
    fi
}

main $@