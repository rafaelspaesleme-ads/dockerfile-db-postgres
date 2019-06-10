#!/bin/bash

echo "Verifying DB $DB_NAME presence ..."
result=`psql -v ON_ERROR_STOP=on -U "$POSTGRES_USER" -d postgres -t -c "SELECT 1 FROM pg_database WHERE datname='$DB_NAME';" | xargs`
if [[ $result == "1" ]]; then
  echo "$DB_NAME DB already exists"
else
  echo "$DB_NAME DB does not exist, creating it ..."

  echo "Verifying role $DB_USER presence ..."
  result=`psql -v ON_ERROR_STOP=on -U "$POSTGRES_USER" -d postgres -t -c "SELECT 1 FROM pg_roles WHERE rolname='$DB_USER';" | xargs`
  if [[ $result == "1" ]]; then
    echo "$DB_USER role already exists"
  else
    echo "$DB_USER role does not exist, creating it ..."
    psql -v ON_ERROR_STOP=on -U "$POSTGRES_USER" <<-EOSQL
      CREATE ROLE $DB_USER WITH LOGIN ENCRYPTED PASSWORD '${DB_PASSWD}';
EOSQL
    echo "$DB_USER role successfully created"
  fi

  psql -v ON_ERROR_STOP=on -U "$POSTGRES_USER" <<-EOSQL
    CREATE DATABASE $DB_NAME WITH OWNER $DB_USER TEMPLATE template0 ENCODING 'UTF8';
    GRANT ALL PRIVILEGES ON DATABASE $DB_NAME TO $DB_USER;
EOSQL
  result=$?
  if [[ $result == "0" ]]; then
    echo "$DB_NAME DB successfully created"
  else
    echo "$DB_NAME DB could not be created"
  fi
fi
