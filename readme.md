# cfn-check-status

This action **checks the status** of a cloudformation stack and **deletes the stack if it is any [FAILED](##cfn-failed-status) status.**

## usage

This action can be used in a cloudformation deployment pipeline. It resolves the pain to delete the stack by hand if the previous deployment resolved in a failed status.

### inputs

#### `stack_name`

**Required** The name of the stack to be checked

```yml
name: cd

on: push

env:
  STACK_NAME: test-stack

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - name: clone the repo
        uses: actions/checkout@v2.5.0
      - name: check status of cloudformation stack prior to deployment
        id: checkstatus
        uses: actions/cfn-check-status@v0.2.0
        with:
          stack-name: env.STACK_NAME
      - name: Get the stack status
        run: |
          echo "Stack status of the previous deployment of $env.STACK_NAME was ${{ steps.checkstatus.outputs }}"
      - name: deploy cloudformation stack
        run: |
          aws cloudformation deploy \
            --template-file=./stack.yml \
            --stack-name=${{ env.STACK_NAME }} \
            --parameter-overrides \
          ...
```

## cfn failed status

The following cloudformation stack status will resolve in stack deletion:

- CREATE_FAILED
- ROLLBACK_FAILED
- UPDATE_FAILED
- UPDATE_ROLLBACK_FAILED
- DELETE_FAILED

see: https://medium.com/nerd-for-tech/cloudformation-status-transition-ea402050c7aa
