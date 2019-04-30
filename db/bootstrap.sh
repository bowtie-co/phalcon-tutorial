#!/bin/bash

APP_ENV=${APP_ENV:-development}

mysql -h $DATABASE_HOST -P $DATABASE_PORT -u $DATABASE_USER -p$DATABASE_PASS < /db/$APP_ENV.bootstrap.sql
