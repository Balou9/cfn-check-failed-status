#!/bin/bash
STACK_NAME="$1"
failed_stack_status=""

function getBucketName() {
  bs1=(${1//:/ })
  bucketstr1=${bs1[1]}
  bs2=(${bucketstr1//,/ })
  bucket_trimmed=${bs2[0]}
  real_bucket_name=$(sed -e 's/^"//' -e 's/"$//' <<<"$bucket_trimmed")
  printf "$real_bucket_name"
}

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

# aws cloudformation describe-stack-events \
#   --stack-name="$STACK_NAME" \
#   | jq -r '.StackEvents[]'

if [[ -z "$failed_stack_status" ]]
then
  output_msg="$STACK_NAME is in a nonfailed status. Stack will not be deleted."
  echo "$output_msg"
else
  output_msg="$STACK_NAME is in $failed_stack_status status. About to be deleted."
  # delete all buckets
  bucket_list_abt_delete=$(
    aws cloudformation describe-stack-events \
      --stack-name=$STACK_NAME \
      | jq -r '.StackEvents[] | select(.ResourceType == "AWS::S3::Bucket") | select((.ResourceStatus | test("CREATE_FAILED")) or .ResourceStatus == "CREATE_IN_PROGRESS") | .ResourceProperties'
  )

  if [[ ! -z "$bucket_list_abt_delete" ]]
  then
    declare -a bucket_list=()
    declare -a bucket_trlist=()

    for bucket in ${bucket_list_abt_delete[@]}; do
      bucket_name=$(getBucketName "$bucket")
      bucket_trlist+=("$bucket_name")
    done

    bucket_list=$(printf "%s\n" "${bucket_trlist[@]}" | sort -u)

    for bucket in $bucket_list; do
      aws s3 rb s3://$bucket --force
    done
  fi

  deletion_ts=$(date +%FT%H:%M)
  aws cloudformation delete-stack --stack-name=$STACK_NAME
  sleep 5

  last_stack_deletion_ts=$(aws cloudformation list-stacks --stack-status-filter="DELETE_COMPLETE" \
    | jq -r \
      --arg STACK_NAME "$STACK_NAME" \
      '[.StackSummaries[] | select(.StackName == $STACK_NAME)][0] | .')

      # '.StackSummaries[] | select(.StackName == $STACK_NAME) | select(.DeletionTime | startswith('\"$DELETION_TIME\"')) | .'

      echo "DEBUG: DELETION TIME STAMP:::::::$deletion_ts\n"
      echo "DEBUG: LAST STACK $STACKNAME DELETION TIME STAMP:::::::$last_stack_deletion_ts\n"

  # [[ "$last_stack_deletion_ts" == "$deletion_ts"* ]] && echo "deletion time verified" || echo "deletion time NOT verified" && exit 1

  echo "$output_msg"
fi

echo "message=$output_msg" >> $GITHUB_OUTPUT
