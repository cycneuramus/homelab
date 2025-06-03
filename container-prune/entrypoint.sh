#!/bin/bash

podman system prune -af --volumes
su - antsva -c 'podman system prune -af --volumes'
