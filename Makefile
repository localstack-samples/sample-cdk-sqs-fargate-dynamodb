export AWS_ACCESS_KEY_ID ?= test
export AWS_SECRET_ACCESS_KEY ?= test
export AWS_DEFAULT_REGION=us-east-1
SHELL := /bin/bash

.PHONY: install init build build_docker test deploy start stop logs

.EXPORT_ALL_VARIABLES:
GOPROXY = direct

usage:		## Show this help
	@fgrep -h "##" $(MAKEFILE_LIST) | fgrep -v fgrep | sed -e 's/\\$//' | sed -e 's/##//'

install: 	## Install dependencies
	@which lstk || npm install -g @localstack/lstk aws-cdk

init:
	cd cdk;\
	npm i

build_docker:
	docker build -t go-fargate .

deploy: build_docker
	cd cdk;\
	lstk cdk bootstrap;\
	lstk cdk deploy ---require-approval never

stop:		## Stop LocalStack
	@lstk stop --non-interactive

logs:		## Save the logs in a separate file
	@lstk logs --non-interactive > logs.txt

start:
	@test -n "${LOCALSTACK_AUTH_TOKEN}" || (echo "LOCALSTACK_AUTH_TOKEN is not set. Find your token at https://app.localstack.cloud/workspace/auth-token"; exit 1)
	LOCALSTACK_AUTH_TOKEN=$(LOCALSTACK_AUTH_TOKEN) LOCALSTACK_DEBUG=1 lstk start

run: start init deploy
	./run.sh
	make stop

test: install start init deploy
	./run.sh;./test.sh;exit_code=`echo $$?`;\
	make stop; exit $$exit_code
