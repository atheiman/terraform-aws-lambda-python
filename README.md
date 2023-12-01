# Terraform AWS Lambda - Python

This project demonstrates how to package and deploy a Python AWS Lambda function with `pip` dependencies using a Lambda layer. Terraform will only plan changes when the Lambda function code ([`lambda/function/`](./lambda/function/)) or [`lambda/layer/requirements.txt`](./lambda/layer/requirements.txt) is updated.
