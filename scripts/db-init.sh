#!/bin/bash

echo "Verificando se DB $DB_NAME esta presente..."
result=`psql -v ON_ERROR_STOP=on -U "$POSTGRES_USER" -d postgres -t -c "SELECT 1 FROM pg_database WHERE datname='$DB_NAME';" | xargs`
if [[ $result == "1" ]]; then
  echo "$DB_NAME DB já existe."
else
  echo "$DB_NAME DB não existe... criando..."

  echo "Verificando se há regras de $DB_USER presente..."
  result=`psql -v ON_ERROR_STOP=on -U "$POSTGRES_USER" -d postgres -t -c "SELECT 1 FROM pg_roles WHERE rolname='$DB_USER';" | xargs`
  if [[ $result == "1" ]]; then
    echo "Regras do usuário $DB_USER existente."
  else
    echo "Regras do usuário $DB_USER não existe, criando..."
    psql -v ON_ERROR_STOP=on -U "$POSTGRES_USER" <<-EOSQL
      CREATE ROLE $DB_USER WITH LOGIN ENCRYPTED PASSWORD '${DB_PASSWD}';
EOSQL
    echo "regras do usuário $DB_USER criado com sucesso!"
  fi

  psql -v ON_ERROR_STOP=on -U "$POSTGRES_USER" <<-EOSQL
    CREATE DATABASE $DB_NAME WITH OWNER $DB_USER TEMPLATE template0 ENCODING 'UTF8';
    GRANT ALL PRIVILEGES ON DATABASE $DB_NAME TO $DB_USER;
EOSQL
  result=$?
  if [[ $result == "0" ]]; then
    echo "DB $DB_NAME criado com sucesso!"
  else
    echo "DB $DB_NAME não criado."
  fi
fi
