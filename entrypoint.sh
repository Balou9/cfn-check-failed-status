#!/bin/bash
STACK_NAME="$1"
echo "$STACK_NAME"
stack_status=$(aws cloudformation describe-stacks \
  --stack-name="$STACK_NAME" \
  | jq ".Stacks[].StackStatus")

echo "$stack_status"
if [[ "$stack_status" == "CREATE_FAILED" ]] || [[ "$stack_status" == "ROLLBACK_FAILED" ]] || [[ "$stack_status" == "UPDATE_FAILED" ]] || [[ "$stack_status" == "UPDATE_ROLLBACK_FAILED" ]] || [[ "$stack_status" == "DELETE_FAILED" ]]
then
  echo "$STACK_NAME" " is in " $stack_status " status. About to be deleted."
  aws delete-stack --stack-name=$STACK_NAME
else
  echo "$STACK_NAME" " is in " $stack_status " status"
fi
