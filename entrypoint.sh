#!/bin/bash
STACK_NAME="$1"
failed_stack_status=""

stack_status_list=$(aws cloudformation describe-stack-events \
  --stack-name="$STACK_NAME" \
  | jq -r '.StackEvents[].ResourceStatus'
)

for status in $stack_status_list; do
  echo "$status"
  if [[ $status = 'CREATE_FAILED' ]] || [[ $status = 'ROLLBACK_FAILED' ]] || [[ $status = 'UPDATE_FAILED' ]] || [[ $status = 'UPDATE_ROLLBACK_FAILED' ]] || [[ $status = 'DELETE_FAILED' ]];
  then
    failed_stack_status=$status
  fi
done

debug_list=$(aws cloudformation describe-stack-events \
  --stack-name="$STACK_NAME" \
  | jq -r '.StackEvents[]'
)

echo "$debug_list"

if [[ -z "$failed_stack_status" ]]
then
  output_msg="$STACK_NAME is in a nonfailed status. Stack will not be deleted."
else
  output_msg="$STACK_NAME is in $failed_stack_status status. About to be deleted."
  # delete all buckets
  bucket_list_abt_delete=$(
    aws cloudformation describe-stack-events \
      --stack-name=$STACK_NAME \
      | jq -r '.StackEvents[] | select(.ResourceType == "AWS::S3::Bucket") | select(.ResourceStatus == "CREATE_IN_PROGRESS|CREATE_FAILED") | .PhysicalResourceId'
  )

  echo "$bucket_list_abt_delete"

  if [[ ! -z "$bucket_list_abt_delete" ]]
  then
    for bucket in $bucket_list_abt_delete; do
      aws s3 rb s3://$bucket --force
    done
  fi

  aws cloudformation delete-stack --stack-name=$STACK_NAME
fi

echo "message=$output_msg" >> $GITHUB_OUTPUT
echo "$output_msg"
