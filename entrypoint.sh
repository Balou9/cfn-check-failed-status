#!/bin/sh
STACK_NAME="$1"
echo "$STACK_NAME"
stack_status=$(aws cloudformation describe-stacks \
  --stack-name="$1" \
  | jq ".Stacks[].StackStatus")

if [ "$stack_status" == "CREATE_FAILED" ] ||  [ "$stack_status" == "ROLLBACK_FAILED" ] || [ "$stack_status" == "UPDATE_FAILED" ] || [ "$stack_status" == "UPDATE_ROLLBACK_FAILED" ] || [ "$stack_status" == "DELETE_FAILED" ]
then
  echo "$1" " is in " $stack_status " status. About to be deleted." >> $GITHUB_OUTPUT
  aws delete-stack --stack-name=$1
else
  echo "$1" " is in " $stack_status " status" >> $GITHUB_OUTPUT
fi
