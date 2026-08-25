#!/bin/bash
set -e

# The official mysql image only grants MYSQL_USER access to MYSQL_DATABASE on
# first init. Rails also needs a test database, so grant broadly rather than
# guessing the exact test DB name.
mysql -uroot -p"$MYSQL_ROOT_PASSWORD" <<-EOSQL
  GRANT ALL PRIVILEGES ON *.* TO '$MYSQL_USER'@'%';
  FLUSH PRIVILEGES;
EOSQL
