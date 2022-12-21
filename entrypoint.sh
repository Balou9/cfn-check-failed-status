#!/bin/bash
STACK_NAME="$1"
stack_status=""

stack_status_list=$(aws cloudformation describe-stack-events \
  --stack-name="$STACK_NAME" \
  | jq ".StackEvents[].ResourceStatus")

for status in $stack_status_list
do
  if [[ $status = '"CREATE_FAILED"' ]] || [[ $status = '"ROLLBACK_FAILED"' ]] || [[ $status = '"UPDATE_FAILED"' ]] || [[ $status = '"UPDATE_ROLLBACK_FAILED"' ]] || [[ $status = '"DELETE_FAILED"' ]]; then
    echo "RECENT STACK EVENTS:"
    failed_stack_status=$status
    echo "STACK in FAILED STATUS ... $failed_stack_status"
  fi
done

if [[ -z "$failed_stack_status" ]]
then
  output_msg="$STACK_NAME is in a nonfailed status. Stack will not be deleted."
else
  output_msg="$STACK_NAME is in $failed_stack_status status. About to be deleted."
  aws cloudformation delete-stack --stack-name=$STACK_NAME
fi

echo "message=$output_msg" >> $GITHUB_OUTPUT
echo "$output_msg"
