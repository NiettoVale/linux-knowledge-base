#!/bin/bash

function check_machine_exists() {
    local machine_name="$1"
    if grep -qE "name: \"$machine_name\"" "$PROJECT_DIR/data/bundle.js"; then
        return 0
    else
        return 1
    fi
}

function check_ip_exists() {
    local ip_address="$1"
    if grep -qE "ip: \"$ip_address\"" "$PROJECT_DIR/data/bundle.js"; then
        return 0
    else
        return 1
    fi
}

function existFile(){
    if [[ -f "$PROJECT_DIR/data/bundle.js" ]]; then
        return 0
    else
        return 1
    fi
}