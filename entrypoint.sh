#!/bin/bash
STACK_NAME="$1"

stack_status_list=$(aws cloudformation describe-stack-events \
  --stack-name="$STACK_NAME" \
  | jq ".StackEvents[].ResourceStatus")

while IFS= read -r line; do
  if [[ "$line" == "CREATE_FAILED" ]] || [[ "$line" == "ROLLBACK_FAILED" ]] || [[ "$line" == "UPDATE_FAILED" ]] || [[ "$line" == "UPDATE_ROLLBACK_FAILED" ]] || [[ "$line" == "DELETE_FAILED" ]]
  then
    stack_status="$line"
    echo "### $line ###"
  else
    echo "$line"
  fi
done <<< "$stack_status_list"

if [[ -z "$stack_status" ]]
then
  echo "$STACK_NAME" " is in "$stack_status" status. About to be deleted."
  aws delete-stack --stack-name=$STACK_NAME
else
  echo "$STACK_NAME" " is in "$stack_status" status"
fi
