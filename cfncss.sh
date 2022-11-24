#!/bin/bash

stack_status=$(aws cloudformation describe-stacks \
  --stack-name=$1 \
  | jq ".Stacks[].StackStatus")


if [ "$stack_status" == "CREATE_FAILED" ] ||  [ "$stack_status" == "ROLLBACK_FAILED" ] || [ "$stack_status" == "UPDATE_FAILED" ] || [ "$stack_status" == "UPDATE_ROLLBACK_FAILED" ] || [ "$stack_status" == "DELETE_FAILED" ]
then
  aws delete-stack --stack-name=$1
fi
