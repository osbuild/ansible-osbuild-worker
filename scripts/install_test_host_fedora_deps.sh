#!/usr/bin/env bash

dnf install -y podman \
  rsync \
  which \
  python3-click-help-colors \
  python3-rich \
  python3-enrich \
  python3-pluggy \
  python3-cookiecutter \
  python3-pip
pip install molecule molecule-podman ansible