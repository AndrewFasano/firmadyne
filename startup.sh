#!/bin/bash
set -e
set -x

export PGPASSWORD=firmadyne
export USER=root

# Start database
echo "firmadyne" | sudo -S service postgresql start
echo "Waiting for DB to start..."
sleep 5

exec "$@"
