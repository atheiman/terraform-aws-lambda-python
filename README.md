# Terraform AWS Lambda - Python

This project demonstrates how to package and deploy a Python AWS Lambda function with `pip` dependencies using a Lambda layer.

- Python dependencies are declared in [`lambda/layer/requirements.txt`](./lambda/layer/requirements.txt). Terraform packages dependencies into `lambda_layer.zip` and uploads as a Lambda layer.
- Python Lambda function code is written in [`lambda/function/`](./lambda/function/). Terraform packages the code into `lambda_function.zip` and is uploaded to Lambda. Separating dependencies into a layer allows Lambda function code to be viewed in the Lambda console ([assuming the function code is less than 3MB](https://docs.aws.amazon.com/lambda/latest/dg/gettingstarted-limits.html)).
- Terraform only applies necessary changes, making `terraform apply` very quick. A new Lambda layer is only created if [`lambda/layer/requirements.txt`](./lambda/layer/requirements.txt) is modified. The Lambda function code is only repackaged if changes are made in [`lambda/function/`](./lambda/function/).
