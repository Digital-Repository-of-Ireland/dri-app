#!/bin/bash
set -e

rm -f /app/tmp/pids/server.pid

if [ "$1" = "rails" ] && [ "$2" = "server" ]; then
  echo "Waiting for MySQL at ${DB_HOST:-db}..."
  until mysqladmin ping -h"${DB_HOST:-db}" -u"${DB_USER:-root}" -p"${DB_PASSWORD:-}" --silent; do
    sleep 1
  done
  echo "MySQL is up."

  #echo "Waiting for Solr at ${SOLR_URL:-http://solr:8983/solr}..."
  #until curl -s -o /dev/null "${SOLR_URL:-http://solr:8983/solr}/admin/ping"; do
  #  sleep 1
  #done
  #echo "Solr is up."
fi

exec "$@"
