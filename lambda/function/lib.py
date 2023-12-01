import boto3
import os
import requests


def get_ec2_instance_ids():
    ec2 = boto3.client("ec2", region_name=os.environ["AWS_REGION"])
    instance_ids = []
    for pg in ec2.get_paginator("describe_instances").paginate():
        for reservations in pg["Reservations"]:
            for instance in reservations["Instances"]:
                instance_ids.append(instance["InstanceId"])
    return instance_ids


def send_http_req():
    r = requests.get("https://httpbin.org/basic-auth/user/pass", auth=("user", "pass"))
    return r.json()
