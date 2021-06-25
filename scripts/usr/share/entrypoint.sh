#!/bin/bash

echo
echo "Welcome $(whoami), from '/usr/share/entrypoint.sh'"
echo
# See: https://unix.stackexchange.com/q/26676
[[ $- == *i* ]] \
    && echo 'This is an interactive shell' \
    || echo 'This is not an interactive shell'

# See: https://unix.stackexchange.com/q/26676
shopt -q login_shell \
    && echo 'This is a login shell' \
    || echo 'This is not a login shell'

echo

if [ ! -f "/etc/ssh/ssh_host_rsa_key" ]; then
	# generate fresh rsa key
	ssh-keygen -f /etc/ssh/ssh_host_rsa_key -N '' -t rsa
fi
if [ ! -f "/etc/ssh/ssh_host_dsa_key" ]; then
	# generate fresh dsa key
	ssh-keygen -f /etc/ssh/ssh_host_dsa_key -N '' -t dsa
fi

#prepare run dir
if [ ! -d "/var/run/sshd" ]; then
  mkdir -p /var/run/sshd
fi

# Run the supplied command w/supplied flags and values
exec "${@}"
