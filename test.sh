#!/bin/bash
# Call the API with each token the Lambda authorizer understands and check
# API Gateway answers the way src/authorizer.js documents it.
set -euo pipefail

STACK_NAME=${STACK_NAME:-sam-app}

URL=$(lstk aws cloudformation describe-stacks --stack-name "$STACK_NAME" \
  --query "Stacks[0].Outputs[?OutputKey=='APIGWEndpoint'].OutputValue" --output text)
echo "API: $URL"

failed=0
# expect <description> <status> <body substring> [curl args...]
expect() {
  local description=$1 status=$2 substring=$3 target_url=$URL response actual
  shift 3
  if [[ "${1:-}" == http* ]]; then
    target_url=$1
    shift
  elif [[ "${1:-}" == /* ]]; then
    target_url="${URL%/}$1"
    shift
  fi
  response=$(curl -sk -m 30 -w '\n%{http_code}' "$target_url" "$@")
  actual=${response##*$'\n'}
  response=${response%$'\n'*}
  if [ "$actual" = "$status" ] && [[ "$response" == *"$substring"* ]]; then
    echo "PASS: $description returned $actual"
  else
    echo "FAIL: $description returned $actual '$response', expected $status with '$substring'"
    failed=1
  fi
}

expect "token 'allow'" 200 "hello world" -H "Authorization: allow"
expect "token 'deny'" 403 "explicit deny" -H "Authorization: deny"
expect "token 'unauthorized'" 401 "Unauthorized" -H "Authorization: unauthorized"
expect "any other token" 500 "" -H "Authorization: none"
expect "no token" 401 "Unauthorized"
expect "whoami token 'allow'" 200 "user" "${URL}whoami" -H "Authorization: allow"

if [ "$failed" != 0 ]; then
  echo "Test failed"
  exit 1
fi
echo "Test passed: the authorizer allowed and denied requests as expected"
