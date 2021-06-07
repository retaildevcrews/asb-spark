#!/bin/sh

# add environment specific commands here

# upgrade packages - faster startup here than in Dockerfile
sudo apt-get update
sudo apt-get upgrade -y
