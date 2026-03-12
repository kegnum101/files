#!/bin/bash

sudo apt update && sudo apt upgrade -y

sudo apt install openssh-server -y

sudo systemctl enable ssh

sudo systemctl start ssh

sudo systemctl status ssh
