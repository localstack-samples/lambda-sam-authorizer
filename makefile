-include .env-local
-include ./devops-tooling/envs.makefile

export AWS_ACCESS_KEY_ID ?= test
export AWS_SECRET_ACCESS_KEY ?= test
export AWS_DEFAULT_REGION=us-east-1
STACK_NAME ?= sam-app
SHELL := /bin/bash

usage:		## Show this help
	@fgrep -h "##" $(MAKEFILE_LIST) | fgrep -v fgrep | sed -e 's/\\$$//' | sed -e 's/##//'

start:		## Start LocalStack
	@test -n "${LOCALSTACK_AUTH_TOKEN}" || (echo "LOCALSTACK_AUTH_TOKEN is not set. Find your token at https://app.localstack.cloud/workspace/auth-token"; exit 1)
	@LOCALSTACK_AUTH_TOKEN=$(LOCALSTACK_AUTH_TOKEN) lstk start

stop:		## Stop LocalStack
	@lstk stop

logs:		## Save the logs in a separate file
	@lstk logs > logs.txt

install:
	npm install --save ulid

deploy: venv	## Deploy the SAM application
	$(VENV_RUN) && lstk sam deploy --stack-name $(STACK_NAME) --resolve-s3 --capabilities CAPABILITY_IAM --no-confirm-changeset

invoke-url: venv
	@$(VENV_RUN) &&	lstk sam list stack-outputs --stack-name $(STACK_NAME) --output json | jq -r '.[0].OutputValue'

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

test:		## Call the API with each token and check the authorizer's decision
	STACK_NAME=$(STACK_NAME) ./test.sh

.PHONY: usage start stop logs install deploy invoke-url invoke-allow invoke-deny invoke-unauthorized invoke-none test
