# cfn-check-status

This action checks status of a cloudformation stack and deletes the stack if it is any FAILED status.

## usage

This action can be used in a cloudformation deployment pipeline. It resolves the pain to delete the stack by hand if the deployment runs in a failed status


```yml
name: ci

on: push

env:
  STACK_NAME: test-coinwatch-stack

jobs:
  test-cfn-check-status:
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
        run: echo "Stack status of $env.STACK_NAME was ${{ steps.checkstatus.outputs }}"

```
