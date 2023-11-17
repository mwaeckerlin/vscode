export PATH="${XDG_RUNTIME_DIR}/bin:$PATH"
eval $(ssh-agent -s)
export SSH_AUTH_SOCK
export SSH_AGENT_PID

export BROWSER=none
export NX_DAEMON=false

echo "Add an SSH Key using: ssh-add /path/to/key"