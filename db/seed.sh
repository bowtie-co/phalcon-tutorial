#!/bin/bash

mysql -h $DATABASE_HOST -u $DATABASE_USER -p$DATABASE_PASS $DATABASE_NAME < /db/bootstrap.sql
