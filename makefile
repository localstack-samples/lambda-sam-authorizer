-include .env-local
-include ./devops-tooling/envs.makefile

export AWS_ACCESS_KEY_ID ?= test
export AWS_SECRET_ACCESS_KEY ?= test
export AWS_DEFAULT_REGION=us-east-1
SHELL := /bin/bash

usage:		## Show this help
	@fgrep -h "##" $(MAKEFILE_LIST) | fgrep -v fgrep | sed -e 's/\\$$//' | sed -e 's/##//'

start:		## Start LocalStack
	@test -n "${LOCALSTACK_AUTH_TOKEN}" || (echo "LOCALSTACK_AUTH_TOKEN is not set. Find your token at https://app.localstack.cloud/workspace/auth-token"; exit 1)
	@LOCALSTACK_AUTH_TOKEN=$(LOCALSTACK_AUTH_TOKEN) localstack start -d

stop:		## Stop LocalStack
	@localstack stop

ready:		## Wait until LocalStack is ready
	@echo Waiting on the LocalStack container...
	@localstack wait -t 30 && echo LocalStack is ready to use! || (echo Gave up waiting on LocalStack, exiting. && exit 1)

logs:		## Save the logs in a separate file
	@localstack logs > logs.txt

install:
	npm install --save ulid

deploy: venv
	$(VENV_RUN) && samlocal deploy -g

invoke-url: venv
	@$(VENV_RUN) &&	samlocal list stack-outputs --stack-name sam-app --output json | jq -r '.[0].OutputValue'

invoke-allow:
	url=$$(make invoke-url) && \
	curl $${url} -H "Authorization: allow"

invoke-deny:
	url=$$(make invoke-url) && \
	curl $${url} -H "Authorization: deny"

invoke-unauthorized:
	url=$$(make invoke-url) && \
	curl $${url} -H "Authorization: unauthorized"

invoke-none:
	url=$$(make invoke-url) && \
	curl $${url} -H "Authorization: none"
