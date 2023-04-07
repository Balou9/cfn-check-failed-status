#!/bin/bash
STACK_NAME="$1"
checked_stack_status=""
# get bucket name from object value

####################################
### observe stack events
# aws cloudformation describe-stack-events \
#   --stack-name="$STACK_NAME" \
#   | jq -r '.StackEvents[]'

####################################

# get bucket name from jq output value
function getBucketName() {
  bs1=(${1//:/ })
  bucketstr1=${bs1[1]}
  bs2=(${bucketstr1//,/ })
  bucket_trimmed=${bs2[0]}
  real_bucket_name=$(sed -e 's/^"//' -e 's/"$//' <<<"$bucket_trimmed")
  printf "$real_bucket_name"
}

# verify stack deletion
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

# get current stack status
function getStackStatus() {
  status=$(aws cloudformation describe-stack-events \
    --stack-name="$1" \
    | jq -r '.StackEvents[0] | select(.ResourceType == "AWS::CloudFormation::Stack") | .ResourceStatus')
  printf "$status"
}

# stack status: reason of FAILED/ROLLBACK_COMPLETE status
# ROLLBACK_COMPLETE: stack deployment fails because the s3 bucket already exists globally
# DELETE_FAILED: stack deployment fails because the s3 bucket in the stack is not empty
# UPDATE_ROLLBACK_COMPLETE: stack update fails because the s3 bucket in the stack already exists

function checkStackStatus () {
  # echo "DEBUG::: in checkStackStatus :::::::: $1"
  status="$1"

  if [[ "$status" = 'CREATE_COMPLETE' ]] || [[ "$status" = 'ROLLBACK_COMPLETE' ]] || [[ "$status" = 'DELETE_FAILED' ]] || [[ "$status" = 'UPDATE_ROLLBACK_COMPLETE' ]];
  then
    stack_status=$status
  fi

  printf "$stack_status"
}

function debuggingHandleResourceStatus() {
  statuuus=$(aws cloudformation describe-stack-events \
    --stack-name="$1" \
    | jq -r '.StackEvents[] | select(.ResourceType != "AWS::CloudFormation::Stack") | .ResourceType + " " + .ResourceStatus + " " + .ResourceId')
  printf "$statuuus"
}

function handleStackStatus() {
  if [[ "$1" = 'CREATE_COMPLETE' ]]
  then
    output_msg="$STACK_NAME is in $1 status. Stack will not be deleted."
    printf "$output_msg \n"
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

    printf "$output_msg \n"
    aws cloudformation delete-stack --stack-name=$STACK_NAME
    verifyStackDeletion "$STACK_NAME"
  fi
}

stack_status=$(getStackStatus "$STACK_NAME")
checked_stack_status=$(checkStackStatus "$stack_status")
printf "$checked_stack_status \n"
handled_stack_status=$(handleStackStatus $checked_stack_status)
printf "$handled_stack_status \n"

# printf "DEBUG::::::::::::::: debuggingHandleResourceStatus \n"
# debugging_resource_status=$(debuggingHandleResourceStatus $STACK_NAME)
# printf "$debugging_resource_status \n"

echo "message=$output_msg" >> $GITHUB_OUTPUT
