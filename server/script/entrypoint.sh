#!/bin/bash
set -e
cmd="$@"

if [ -z "$AWS_REGION_SSM" ]; then
  export AWS_REGION_SSM=us-west-2
fi

# Local testing - Uncomment/Set while testing on local
#export AWS_PROFILE=
#export AWS_REGION=
USE_APP_SERVER="${APP_SERVER:=gunicorn}"

if [ "$FETCH_SSM_PARAM_ENV" == True ]; then
  if [ -z $SSM_PARAM_ENV_NAME ]; then
    echo >&2 "SSM Parameter name not specified even after enabling it's usage. Exiting the container without starting it"
    sleep 5
    exit 1
  else
    echo >&2 "Fetching the SSM Parameter from AWS:"
    echo 'aws ssm get-parameter --with-decryption --name ${SSM_PARAM_ENV_NAME} --region ${AWS_REGION_SSM} | jq -r '.Parameter.Value' > /tmp/.env' >/tmp/ssm_fetch_environ_file.sh
    bash /tmp/ssm_fetch_environ_file.sh
    aws_ssm_parameter_fetch_status=$?
    if [ $aws_ssm_parameter_fetch_status -eq 0 ]; then
      rm /tmp/ssm_fetch_environ_file.sh
      export $(grep -v '^#' /tmp/.env | xargs -d '\n')
    else
      echo >&2 "Unable to access SSM Parameter name specified in the env. Exiting the container without starting it."
      sleep 5
      exit 1
    fi
  fi
fi

if [ -z "$DATABASE_URL" ]; then
  export DATABASE_URL=postgres://$DJANGO_DB_USER:$DJANGO_DB_PASSWORD@$DJANGO_DB_HOST:5432/$DJANGO_DB_NAME
fi

dbhost_check() {
  if ! timeout 2 bash -c "</dev/tcp/${DJANGO_DB_HOST}/5432" 2>/dev/null; then
    echo "The port 5432 doesnt seem to be accessible on database host ${DJANGO_DB_HOST}, please validate the network connectivity.Exiting the container without starting it."
    sleep 5
    exit 1
  fi
}

if [ "$FETCH_SSM_PARAM_ENV" == True ]; then
  dbhost_check
fi

if [ "$ENABLE_CELERY" == "True" ]; then
  >&2 echo "Starting the celery"
  cd $APP_HOME/server && celery -A config worker --beat --loglevel=INFO && celery -A config beat
# -z tests for empty, if TRUE, $cmd is empty
elif [ -z "$cmd" ]; then
  echo >&2 "Running default command "
  if [ "$NOMIGRATE" == True ]; then
    if [ "$DEBUG" == False ]; then
      echo >&2 "DEBUG is set to False."
      if [ "$USE_APP_SERVER" == "gunicorn" ]; then
        gunicorn config.wsgi --timeout 120 --keep-alive 120 -w 2 -b 0.0.0.0:8001 --chdir=$APP_HOME/server --access-logfile=-
      elif [ "$USE_APP_SERVER" == "uwsgi" ]; then
        uwsgi --http :8001 --chdir=$APP_HOME/server --wsgi-file config/wsgi.py --harakiri 120 --http-timeout 120 --master --workers 3 --enable-threads --threads 10 --vacuum
      else
        echo "An invalid application server command was specified. Exiting the container in 5s."
        sleep 5
        exit 1
      fi
    else
      echo >&2 "DEBUG NOT set as False. DONOT RUN with this setting on Production."
      # Uncomment in case local requirements are to be added
      # pip install -r $APP_HOME/requirements/local.txt
      if [ "$USE_APP_SERVER" == "gunicorn" ]; then
        gunicorn config.wsgi --timeout 120 --keep-alive 120 -w 2 -b 0.0.0.0:8001 --chdir=$APP_HOME/server --access-logfile=-
      elif [ "$USE_APP_SERVER" == "uwsgi" ]; then
        uwsgi --http :8001 --chdir=$APP_HOME/server --wsgi-file config/wsgi.py --harakiri 120 --http-timeout 120 --master --workers 3 --enable-threads --threads 10 --vacuum
      else
        echo "An invalid application server command was specified. Exiting the container in 5s."
        sleep 5
        exit 1
      fi
    fi
  else
    echo >&2 "Running migrate command:"
    python $APP_HOME/server/manage.py migrate --noinput
    python $APP_HOME/server/manage.py collectstatic --noinput
    if [ "$DEBUG" == False ]; then
      echo >&2 "DEBUG is set to False."
      if [ "$USE_APP_SERVER" == "gunicorn" ]; then
        gunicorn config.wsgi --timeout 120 --keep-alive 120 -w 2 -b 0.0.0.0:8001 --chdir=$APP_HOME/server --access-logfile=-
      elif [ "$USE_APP_SERVER" == "uwsgi" ]; then
        uwsgi --http :8001 --chdir=$APP_HOME/server --wsgi-file config/wsgi.py --master --workers 3 --enable-threads --threads 10 --vacuum
      else
        echo "An invalid application server command was specified. Exiting the container in 5s."
        sleep 5
        exit 1
      fi
    else
      echo >&2 "DEBUG NOT set as False. DONOT RUN with this setting on Production."
      # Uncomment in case local requirements are to be added
      # pip install -r $APP_HOME/requirements/local.txt
      if [ "$USE_APP_SERVER" == "gunicorn" ]; then
        gunicorn config.wsgi --timeout 120 --keep-alive 120 -w 2 -b 0.0.0.0:8001 --chdir=$APP_HOME/server --access-logfile=-
      elif [ "$USE_APP_SERVER" == "uwsgi" ]; then
        uwsgi --http :8001 --chdir=$APP_HOME/server --wsgi-file config/wsgi.py --harakiri 120 --http-timeout 120 --master --workers 3 --enable-threads --threads 10 --vacuum
      else
        echo "An invalid application server command was specified. Exiting the container in 5s."
        sleep 5
        exit 1
      fi
    fi
  fi
else
  echo >&2 "Running command passed (by the compose file)"
  exec $cmd
fi
