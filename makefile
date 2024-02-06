-include .env-local
-include ./devops-tooling/envs.makefile



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
