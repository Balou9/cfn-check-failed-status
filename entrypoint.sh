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

function verifyStackDeletion() {
  deletion_ts=$(date +%FT%H:%M)
  deletion_allowed_range_ts=$(date -d "+1 min" +%FT%H:%M)
  sleep 5
  last_stack_deletion_ts=$(aws cloudformation list-stacks --stack-status-filter="DELETE_COMPLETE" \
    | jq -r \
      --arg STACK_NAME "$1" \
      '[.StackSummaries[] | select(.StackName == $STACK_NAME)][0] | .DeletionTime'
  )
  [[ "$last_stack_deletion_ts"  == "$deletion_ts"* || $deletion_allowed_range_ts == "$deletion_ts"* ]] && printf "Stack deletion time of the stack $1 verified at $deletion_ts" || printf "Stack deletion time NOT verified, check the aws console if the stack $1 is really deleted."
}

function getStackStatusList() {
  list=$(aws cloudformation describe-stack-events \
    --stack-name="$1" \
    | jq -r '.StackEvents[] | select(.ResourceType == "AWS::CloudFormation::Stack") | .ResourceStatus')
  printf "$list"
}

function getStackStatus () {
  # check and save final stack status
  for status in $stack_status_list; do
    if [[ $status = 'CREATE_FAILED' ]] || [[ $status = 'DELETE_FAILED' ]] || [[ $status = 'UPDATE_ROLLBACK_COMPLETE' ]];
    then
      stack_status=$status
    fi
  done
  printf "$stack_status"
}

function debuggingGetStackStatus() {
  statuuus=$(aws cloudformation describe-stack-events \
    --stack-name="$1" \
    | jq -r '.StackEvents[] | .ResourceType + " " + .ResourceStatus')
  printf "$statuuus"
}

function handleStackStatus() {
  if [[ -z "$1" ]]
  then
    output_msg="$STACK_NAME is in a nonfailed status. Stack will not be deleted."
    printf "$output_msg"
  else
    output_msg="$STACK_NAME is in $1 status. About to be deleted."
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

    printf "$output_msg"
    aws cloudformation delete-stack --stack-name=$STACK_NAME
    verifyStackDeletion "$STACK_NAME"
  fi
}

printf "DEBUG::::::::::::::: getStackStatusList \n"
stack_status_list=$(getStackStatusList "$STACK_NAME")
printf "$stack_status_list \n"

printf "DEBUG::::::::::::::: getStackStatus \n"
failed_stack_status=$(getStackStatus "$stack_status_list")
printf "$failed_stack_status \n"

printf "\n DEBUG::::::::::::::: debuggingGetStackStatus \n"
debugging_stack_status=$(debuggingGetStackStatus $STACK_NAME)
printf "$debugging_stack_status \n"

printf "\n DEBUG::::::::::::::: handleStackStatus \n"
handle_stack_status=$(handleStackStatus $failed_stack_status)
printf "$handle_stack_status \n"

echo "message=$output_msg" >> $GITHUB_OUTPUT
