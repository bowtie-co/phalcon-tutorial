#!/bin/bash

error() {
  red='\033[0;31m'
  nocolor='\033[0m'
  prefix="======>>  "
  suffix="  <<======"
  echo
  echo -e "${red}${prefix}${1}${suffix}${nocolor}"
  echo
}

log() {
  yellow='\033[0;33m'
  nocolor='\033[0m'
  prefix="======>>  "
  suffix="  <<======"
  echo
  echo -e "${yellow}${prefix}${1}${suffix}${nocolor}"
  echo
}

fail() {
  msg=${1:-Failure}
  code=${2:-1}

  error "FATAL: $msg"

  exit $code
}

has_env_var() {
  env | grep "$1" > /dev/null 2>&1
  return $?
}

missing_env_var() {
  if has_env_var $1; then
    return 1
  else
    return 0
  fi
}

APP_ENV=${APP_ENV:-development}
ENV_FILE="/.env.$APP_ENV"

if [ ! -f $ENV_FILE ]; then
  fail "Missing ENV file: $ENV_FILE"
fi

ENV_VARS=$(sops -d $ENV_FILE 2> /dev/null)

if [[ "$?" != "0" ]]; then
  ENV_VARS=$(cat $ENV_FILE)
fi

export $(echo $ENV_VARS | xargs)

REQUIRED_ENV_VARS="
DATABASE_HOST
DATABASE_PORT
DATABASE_USER
DATABASE_PASS
DATABASE_NAME
"

for v in $REQUIRED_ENV_VARS; do
  if missing_env_var "$v"; then
    fail "Missing required ENV VAR: '$v'"
  fi
done

/wait-for-it.sh $DATABASE_HOST:$DATABASE_PORT -t 30

if [ ! -z "$REDIS_HOST" ] && [ ! -z "$REDIS_PORT" ]; then
  /wait-for-it.sh $REDIS_HOST:$REDIS_PORT -t 30
fi

if [[ "$APP_ENV" == "development" ]]; then
  log "App is running in development, attempt to initialize database ..."

  mysql -h ${DATABASE_HOST} -P ${DATABASE_PORT} -u root -p${MYSQL_ROOT_PASSWORD} -e "set @@global.sql_mode = '';"
  (\
    mysql -h ${DATABASE_HOST} -P ${DATABASE_PORT} -u root -p${MYSQL_ROOT_PASSWORD} -e "create database ${DATABASE_NAME}" \
    && mysql -h ${DATABASE_HOST} -P ${DATABASE_PORT} -u root -p${MYSQL_ROOT_PASSWORD} ${DATABASE_NAME} < /db/${APP_ENV}.seed.sql\
  ) || log "Using existing DB: ${DATABASE_NAME} | Reset this by running 'docker volume rm phalcontutorial_db'"
fi

exec "$@"
