[![ci](https://github.com/Balou9/cfn-check-failed-status/workflows/ci/badge.svg)](https://github.com/Balou9/cfn-check-failed-status/actions)

# cfn-check-failed-status

**### wip ###**

A Github action that checks the status of a aws cloudformation stack and deletes the stack if the previous deployment resolved in a failed status. It resolves the pain to manually delete the stack during the deployment process.

## usage

```yml
jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:  
      - name: check status of cloudformation stack prior to deployment
      - uses: Balou9/cfn-check-failed-status@v0.1
        with:
          cfn-stack-name: example-stack
```

#### inputs

###### `cfn-stack-name`

**Required** The name of the stack to be status checked

#### outputs

###### `message`

`<stack-name> is in a nonfailed status. Stack will not be deleted.`  
status message non-failed stack status

`<stack-name>  is in CREATE_FAILED status. About to be deleted.`   
status message failed stack status

---

## motivation

cfn-check-failed-status is driven by the idea to be able to redeploy aws cloudformation stacks
conveniently. During the development process you discover that your stack is in
XXX_FAILED status. If redeploy your stack
the github actions pipeline will fail since a stack in XXX_FAILED status cannot be updated.

This action ensures that your pipeline is able to complete every deployment run successfully.
Of course still your pipeline can fail due to validation or stack errors.
But by using this action you can

- reduce the amount of times you have to manually delete your cloudformation stack in the aws console
- reduce the amount of times you have to manually delete relevant stack resources (e.g. S3 Buckets)
- reduce github action pipeline runs

## feat: cfn stack deletion on failed status


- CREATE_FAILED (stack creation failed )
- DELETE_FAILED (stack deletion failed)
- UPDATE_ROLLBACK_COMPLETE (stack resource update failed)


**todo**

- ROLLBACK_FAILED
- UPDATE_FAILED
- UPDATE_ROLLBACK_FAILED

<!-- see: https://medium.com/nerd-for-tech/cloudformation-status-transition-ea402050c7aa   
and: https://aws.amazon.com/premiumsupport/knowledge-center/cloudformation-stack-delete-failed/ -->

# License

[GPL-2.0](docs/license.md)
