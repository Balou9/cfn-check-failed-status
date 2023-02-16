#!/bin/bash
STACK_NAME="$1"
failed_stack_status=""

stack_status_list=$(aws cloudformation describe-stack-events \
  --stack-name="$STACK_NAME" \
  | jq -r '.StackEvents[].ResourceStatus'
)

function getBucketName() {
  bs1=(${1//:/ })
  bucketstr1=${bs1[1]}
  bs2=(${bucketstr1//,/ })
  bucket_trimmed=${bs2[0]}
  real_bucket=$(sed -e 's/^"//' -e 's/"$//' <<<"$bucket_trimmed")
  printf "$real_bucket"
}

for status in $stack_status_list; do
  echo "$status"
  if [[ $status = 'CREATE_FAILED' ]] || [[ $status = 'ROLLBACK_FAILED' ]] || [[ $status = 'UPDATE_FAILED' ]] || [[ $status = 'UPDATE_ROLLBACK_FAILED' ]] || [[ $status = 'DELETE_FAILED' ]];
  then
    failed_stack_status=$status
  fi
done

aws cloudformation describe-stack-events \
  --stack-name="$STACK_NAME" \
  | jq -r '.StackEvents[]'

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

  echo "BUCKETS_TO_DEL_LIST before the trim: $bucket_list_abt_delete"

  if [[ ! -z "$bucket_list_abt_delete" ]]
  then
    declare -a bucket_list=()
    declare -a bucket_trlist=()

    for bucket in ${bucket_list_abt_delete[@]}; do
      bucket_name=$(getBucketName "$bucket")
      # printf "debug::: testing getBucketName:::: $bucket_name"
      bucket_trlist+=("$bucket_name")
    done

    printf "debug:::: tests getBucketName full result::::: $bucket_trlist"

    for ((i=0; i<${#bucket_list_abt_delete[@]}; i++)); do
      bs1=(${bucket_list_abt_delete[i]//:/ })
      bucketstr1=${bs1[1]}
      bs2=(${bucketstr1//,/ })
      bucket_trimmed=${bs2[0]}
      printf "bucket name trimmed: $bucket_trimmed"
##### debug and echo / printf printing in for loops
      real_bucket=$(sed -e 's/^"//' -e 's/"$//' <<<"$bucket_trimmed")
      # bucket_list_abt_delete[i]=$real_bucket
      printf "tha real bucket name: $real_bucket"

      # echo ${bucket_list_abt_delete[i]}
    done


    echo "BUCKETS_TO_DEL_LIST after the trim: $bucket_list"


    for bucket in $bucket_list; do
      aws s3 rb s3://$bucket --force
    done
  fi

  aws cloudformation delete-stack --stack-name=$STACK_NAME
  echo "$output_msg"
fi

echo "message=$output_msg" >> $GITHUB_OUTPUT
