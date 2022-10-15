# just manual: https://github.com/casey/just#readme

_default:
	just --list

# Builds all docker images
docker:
  #!/bin/bash -eux
  DOCKER_FLAGS="--ssh default --build-arg ENVIRONMENT=production"
  export DOCKER_BUILDKIT=1
  docker build . ${DOCKER_FLAGS} --target base --tag registry.fly.io/hapsoc-ci

# Push the docker image to fly
docker-push:
  just docker
  docker push registry.fly.io/hapsoc-ci:latest

# Starts a fly machine for ci
run *args:
  #!/bin/bash -eux
  just docker-push
  fly m run \
    --region iad \
    --size shared-cpu-8x \
    --volume ci:/vol \
    registry.fly.io/hapsoc-ci:latest {{args}}

update id *args:
  #!/bin/bash -eux
  just docker-push
  fly m update {{id}} \
    --size shared-cpu-8x \
    {{args}}
