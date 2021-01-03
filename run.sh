#!/bin/bash

# Set sane bash defaults
set -o errexit
set -o pipefail

OPTION="$1"
ACCESS_KEY=${ACCESS_KEY:?"ACCESS_KEY required"}
SECRET_KEY=${SECRET_KEY:?"SECRET_KEY required"}
S3PATH=${S3PATH:?"S3_PATH required"}
CRON_SCHEDULE=${CRON_SCHEDULE:-0 3 * * 6}
S3CMDPARAMS=${S3CMDPARAMS}

LOCKFILE="/tmp/s3cmd.lock"
LOG="/var/log/s3backup.log"

trap "rm -f $LOCKFILE" EXIT

if [ ! -e $LOG ]; then
  touch $LOG
fi

if [[ $OPTION = "start" ]]; then
  echo "Found the following files to sync:"
  echo
  ls -F /backup
  echo

  if grep -Fxq "$ACCESS_KEY" /root/.s3cfg; then
    echo "ACCESS_KEY already exists in /root/s3cfg"
  else
    sed -i 's@access_key =@access_key = '"$ACCESS_KEY"'@g' /root/.s3cfg
  fi
  
  if grep -Fxq "$SECRET_KEY" /root/.s3cfg; then
    echo "SECRET_KEY already exists in /root/s3cfg"
  else
    sed -i 's@secret_key =@secret_key = '"$SECRET_KEY"'@g' /root/.s3cfg
  fi
  

  chmod 600 /root/.s3cfg

  echo "Running backup on the following CRON schedule: $CRON_SCHEDULE"
  echo "$CRON_SCHEDULE bash /run.sh backup" | crontab - && crond -f -L /dev/stdout

elif [[ $OPTION = "backup" ]]; then
  echo "Starting sync: $(date)" | tee $LOG

  if [ -f $LOCKFILE ]; then
    echo "$LOCKFILE detected, exiting! Already running?" | tee -a $LOG
    exit 1
  else
    touch $LOCKFILE
  fi

  echo "Executing s3cmd sync $S3CMDPARAMS /backup/ $S3PATH..." | tee -a $LOG
  s3cmd sync $S3CMDPARAMS /backup/ $S3PATH 2>&1 | tee -a $LOG
  rm -f $LOCKFILE
  echo "Finished sync: $(date)" | tee -a $LOG

else
  echo "Unsupported option: $OPTION" | tee -a $LOG
  exit 1
fi
