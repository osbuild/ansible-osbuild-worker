#!/usr/bin/env bash

sudo mkdir -p /etc/containers

sudo tee -a /etc/containers/storage.conf <<EOF
[storage]
driver = "vfs"
runroot = "/run/containers/storage"
graphroot = "/var/lib/containers/storage"
EOF
