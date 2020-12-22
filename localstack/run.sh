#!/bin/bash

cd "$(dirname "$0")"

export SERVICES=s3,kinesis,firehose,dynamodb,lambda,ec2,iam,sts,cloudwatch
export TMPDIR=/private$TMPDIR
export PORT_WEB_UI=8080
export DEBUG=0

case $1 in
  down)
    docker-compose down
    ;;
  up)
    docker-compose up -d
    ;;
  *)
    echo "ex) ./run.sh down or up"
    ;;
esac
