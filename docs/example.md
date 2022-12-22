#### example usage in deployment pipeline

```yml
name: cd

on: push

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - name: clone the repo
        uses: actions/checkout@v2.5.0

      - name: configure aws credentials
        uses: aws-actions/configure-aws-credentials@v1.5.3
        with:
          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          aws-region: ${{ env.AWS_REGION }}

      - name: validates cloudformation template
        run: |
          aws cloudformation validate-template \
            --template-body="./stack.yml"

      - name: check status of cloudformation stack prior to deployment
        id: checkstatus
        uses: ./
        with:
          stack-name: ${{ env.STACK_NAME }}

      - name: Get the stack status
        run: |
          echo "${{ steps.checkstatus.outputs.message }}"

      - name: configure the environment
        run: |
          echo "STACK_NAME=test-stack231" >> $GITHUB_ENV
#          echo ...

      - name: deploy cloudformation stack
        run: |
          aws cloudformation deploy \
            --template-file=./stack.yml \
            --stack-name=${{ env.STACK_NAME }} \
            --parameter-overrides \
          ...
```
