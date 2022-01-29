#!/bin/bash

_USERNAME=$1
_PASSWD=$2
SUCCESS=0
FAILURE=1
NUM_OF_ARGS=$#

function get_script_name {
    echo "[$(basename $0)] " | awk '{print toupper($0)}'
}

function is_user_exists {
    local username=$1

    # Check if user already exists.
    id -u "$username" > /dev/null  /etc/passwd

    if [ $? -eq $SUCCESS ]; then
        echo "$(get_script_name) User '$username' already exists."
        return "$SUCCESS"
    fi

    return "$FAILURE"
}

function is_group_exists {
    local group=$1

    # Check if group already exists.
    getent group "$group"

    if [ $? -eq $SUCCESS ]; then
        echo "$(get_script_name) Group '$group' already exists."
        return "$SUCCESS"
    fi

    return "$FAILURE"
}

function add_user {
    local username=$1
    local _alt_flags="${@:2}"

    useradd $_alt_flags --shell /bin/bash --user-group  "$username"
}

function add_user_passwd {
    local username=$1
    local passwd=$2

    echo "$username:$passwd" | sudo chpasswd
}

function main {
    local username=$1
    local passwd=$2
    local admin_group=${3-"provisioner"}

    if ! is_group_exists "$admin_group"; then
        echo "$(get_script_name) Creating custom group $admin_group ....."
        groupadd "$admin_group"
    fi

    if ! is_user_exists "$username"; then
        echo "$(get_script_name) Creating custom user $username ....."

        add_user "$username" --create-home --home-dir /home/"$username" --groups sudo,"$admin_group"

        add_user_passwd "$username" "$passwd"

        echo "$(get_script_name) The accounts are setup."
    fi
}

if [ "$NUM_OF_ARGS" -eq 2 ]; then

    main "$_USERNAME" "$_PASSWD"

else
    echo  "$(get_script_name) This programm needs atleast 2 arguments you have given $# "
    echo  "$(get_script_name) you have to call the script $0 with your desired a username and password."
    exit "$FAILURE"
fi