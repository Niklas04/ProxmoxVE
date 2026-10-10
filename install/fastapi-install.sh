#!/usr/bin/env bash

# Copyright (c) 2021-2026 tteck
# Author: tteck (tteckster) | Co-Author: CrazyWolf13, MickLesk
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt install -y \
  git \
  osmium-tool
msg_ok "Installed Dependencies"

PYTHON_VERSION="3.13" setup_uv

msg_info "Installing FastAPI"
mkdir -p /opt/fastapi-app
$STD uv venv --clear /opt/fastapi-app/.venv
$STD /opt/fastapi-app/.venv/bin/python -m ensurepip --upgrade
$STD /opt/fastapi-app/.venv/bin/python -m pip install --upgrade pip
$STD /opt/fastapi-app/.venv/bin/python -m pip install "fastapi[standard]"
$STD /opt/fastapi-app/.venv/bin/python -m pip install pyhgtmap
$STD /opt/fastapi-app/.venv/bin/python -m pip install itsdangerous psutil
cat <<EOF >/opt/fastapi-app/main.py
from fastapi import FastAPI

app = FastAPI()

@app.get("/")
def read_root():
    return {"message": "Hallo Welt!"}
EOF
msg_ok "Installed FastAPI"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/fastapi.service
[Unit]
Description=FastAPI App
After=network.target

[Service]
User=root
WorkingDirectory=/opt/fastapi-app
ExecStart=/opt/fastapi-app/.venv/bin/uvicorn main:app --host 0.0.0.0 --port 80
Restart=always

[Install]
WantedBy=multi-user.target
EOF

systemctl enable -q --now fastapi
msg_ok "Created Service"

motd_ssh
customize
cleanup_lxc
