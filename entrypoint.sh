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
# enter similar keys to get the names of S3 Buckets which where created initially
debug_list=$(aws cloudformation describe-stack-events \
  --stack-name="$STACK_NAME" \
  | jq -r '.StackEvents[] | select(.ResourceType == "AWS::S3::Bucket") | select((.ResourceStatus | test("CREATE_FAILED")) or .ResourceStatus == "CREATE_IN_PROGRESS") | [.ResourceType, .PhysicalResourceId, .ResourceProperties, .ResourceStatus]'
)

aws cloudformation describe-stack-events \
  --stack-name="$STACK_NAME" \
  | jq -r '.StackEvents[]'


echo "DEBUG_LIST: $debug_list"

if [[ -z "$failed_stack_status" ]]
then
  output_msg="$STACK_NAME is in a nonfailed status. Stack will not be deleted."
else
  output_msg="$STACK_NAME is in $failed_stack_status status. About to be deleted."
  # delete all buckets
  bucket_list_abt_delete=$(
    aws cloudformation describe-stack-events \
      --stack-name=$STACK_NAME \
      | jq -r '.StackEvents[] | select(.ResourceType == "AWS::S3::Bucket") | select((.ResourceStatus | test("CREATE_FAILED")) or .ResourceStatus == "CREATE_IN_PROGRESS") | .ResourceProperties'
  )

  echo "BUCKETS_TO_DEL_LIST: $bucket_list_abt_delete"

  if [[ ! -z "$bucket_list_abt_delete" ]]
  then
    for ((i=0; i<${#bucket_list_abt_delete[@]}; i++)); do
      bs1=(${bucket_list_abt_delete[$i]//:/ })
      bucketstr1=${bs1[1]}
      bs2=(${bucketstr1//,/ })
      bucket_trimmed=${bs2[0]}
      
      real_bucket=$(sed -e 's/^"//' -e 's/"$//' <<<"$bucket_trimmed")
      bucket_list_abt_delete[$i]=$real_bucket
      echo ${bucket_list_abt_delete[$i]}
    done

    # for bucket in $bucket_list_abt_delete; do
    #   bs1=(${bucket//:/ })
    #   bucketstr1=${bs1[1]}
    #   bs2=(${bucketstr1//,/ })
    #
    #   bucket_trimmed=${bs2[0]}
    #   real_bucket=$(sed -e 's/^"//' -e 's/"$//' <<<"$bucket_trimmed")
    # done

    for bucket in $bucket_list_abt_delete; do
      aws s3 rb s3://$bucket --force
    done
  fi

  aws cloudformation delete-stack --stack-name=$STACK_NAME
fi

echo "message=$output_msg" >> $GITHUB_OUTPUT
echo "$output_msg"
