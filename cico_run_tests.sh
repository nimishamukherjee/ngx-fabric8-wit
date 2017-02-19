#!/bin/bash

# Show command before executing
set -x

# Exit on error
set -e

# We need to disable selinux for now, XXX
/usr/sbin/setenforce 0

# Get all the deps in
yum -y install \
  docker \
  make \
  git
service docker start

# Build builder image
docker build -t ngx-fabric8-wit-builder -f Dockerfile.builder .
mkdir -p dist && docker run --detach=true --name=ngx-fabric8-wit-builder -e "API_URL=http://demo.api.almighty.io/api/" -t -v $(pwd)/dist:/dist:Z ngx-fabric8-wit-builder

# Build almighty-ui
docker exec ngx-fabric8-wit-builder npm install

## Exec unit tests
docker exec ngx-fabric8-wit-builder ./run_unit_tests.sh

if [ $? -eq 0 ]; then
  echo 'CICO: unit tests OK'
else
  echo 'CICO: unit tests FAIL'
  exit 1
fi

## Exec functional tests
docker exec ngx-fabric8-wit-builder ./run_functional_tests.sh
