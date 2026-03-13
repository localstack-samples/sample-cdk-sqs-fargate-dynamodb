export AWS_ACCESS_KEY_ID ?= test
export AWS_SECRET_ACCESS_KEY ?= test
export AWS_DEFAULT_REGION=us-east-1
SHELL := /bin/bash

.PHONY: install init build build_docker test deploy start stop ready logs

.EXPORT_ALL_VARIABLES:
GOPROXY = direct
NETWORK_NAME="localstack-shared-net"

usage:		## Show this help
	@fgrep -h "##" $(MAKEFILE_LIST) | fgrep -v fgrep | sed -e 's/\\$//' | sed -e 's/##//'

install: 	## Install dependencies
	@which localstack || pip install localstack
	@which awslocal || pip install awscli-local

init:
	cd cdk;\
	npm i

build_docker:
	docker build -t go-fargate .

deploy: build_docker
	cd cdk;\
	cdklocal bootstrap;\
	cdklocal deploy ---require-approval never

stop:		## Stop LocalStack
	@localstack stop

ready:		## Wait until LocalStack is ready
	@echo Waiting on the LocalStack container...
	@localstack wait -t 30 && echo LocalStack is ready to use! || (echo Gave up waiting on LocalStack, exiting. && exit 1)

logs:		## Save the logs in a separate file
	@localstack logs > logs.txt

start:
	@test -n "${LOCALSTACK_AUTH_TOKEN}" || (echo "LOCALSTACK_AUTH_TOKEN is not set. Find your token at https://app.localstack.cloud/workspace/auth-token"; exit 1)
	-docker network create $(NETWORK_NAME) 2> /dev/null;
	LOCALSTACK_AUTH_TOKEN=$(LOCALSTACK_AUTH_TOKEN) LAMBDA_DOCKER_NETWORK=$(NETWORK_NAME) DOCKER_FLAGS="--network $(NETWORK_NAME)" DEBUG=1 localstack start -d

run: start init deploy
	./run.sh
	make stop

test: install start init deploy
	./run.sh;./test.sh;exit_code=`echo $$?`;\
	make stop; exit $$exit_code
