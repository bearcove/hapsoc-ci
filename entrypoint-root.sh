#!/bin/bash -eux

chown ci:ci /vol
su ci -c "bash ./entrypoint-user.sh"
