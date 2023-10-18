# just manual: https://github.com/casey/just#readme

_default:
	just --list

# Builds all docker images
docker:
  #!/bin/bash -eux
  DOCKER_FLAGS="--build-arg ENVIRONMENT=production"
  export DOCKER_BUILDKIT=1
  docker build . ${DOCKER_FLAGS} --target base --tag registry.fly.io/hapsoc-ci

# Push the docker image to fly
docker-push:
  just docker
  docker push registry.fly.io/hapsoc-ci:latest

# Starts a fly machine for ci
run *args:
  #!/bin/bash -eux
  fly m run \
    --region iad \
    --cpus 8 \
    --memory 4096 \
    --volume ci:/vol \
    registry.fly.io/hapsoc-ci:latest {{args}}

update id *args:
  #!/bin/bash -eux
  fly m update {{id}} \
    --cpus 8 \
    --memory 4096 \
    {{args}}
