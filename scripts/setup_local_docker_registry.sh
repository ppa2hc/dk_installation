#!/bin/bash

DAEMON_JSON="/etc/docker/daemon.json"
REGISTRY="localhost:5000"

if [ ! -f "$DAEMON_JSON" ]; then
  echo "File $DAEMON_JSON does not exist. Creating with insecure-registries set to [\"$REGISTRY\"]"
else
  echo "File $DAEMON_JSON exists. Overwriting with insecure-registries set to [\"$REGISTRY\"]"
  # Optionally back up existing file:
  sudo cp "$DAEMON_JSON" "${DAEMON_JSON}.bak.$(date +%s)"
  echo "Backup saved as ${DAEMON_JSON}.bak.$(date +%s)"
fi

sudo tee "$DAEMON_JSON" > /dev/null <<EOF
{
  "insecure-registries": ["$REGISTRY"]
}
EOF

echo "Done. Restart Docker daemon to apply changes:"
systemctl restart docker
echo "Restart Docker daemon done."

echo "start docker registry"
docker volume create local-registry-data
docker kill dk_local_registry
docker rm dk_local_registry
docker run -d -p 5000:5000 --restart=unless-stopped --name dk_local_registry -v local-registry-data:/var/lib/registry registry:2

