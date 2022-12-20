#!/bin/bash
STACK_NAME="$1"
stack_status=""

stack_status_list=$(aws cloudformation describe-stack-events \
  --stack-name="$STACK_NAME" \
  | jq ".StackEvents[].ResourceStatus")

echo $stack_status_list

echo "RECENT STACK EVENTS:"

for status in $stack_status_list
do
  if [ $status = '"CREATE_FAILED"' ] || [ $status = '"ROLLBACK_FAILED"' ] || [ $status = '"UPDATE_FAILED"' ] || [ $status = '"UPDATE_ROLLBACK_FAILED"' ] || [ $status = '"DELETE_FAILED"' ]; then
    stack_status=$status
  fi
done

echo "STACK STATUS af ... $stack_status"

if [[ -z "$stack_status" ]]
then
  output_msg="stack name...... $STACK_NAME"
  echo "$output_msg"
  # echo "{message}={$output_msg}" >> $GITHUB_OUTPUT
else
  output_msg="$STACK_NAME is in $stack_status status. About to be deleted."
  echo "$output_msg"
  # echo "{message}={$output_msg}" >> $GITHUB_OUTPUT
  aws cloudformation delete-stack --stack-name=$STACK_NAME
fi
