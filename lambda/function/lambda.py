import json
import lib


def handler(event, context):
    print(json.dumps(event, default=str))
    print(lib.get_ec2_instance_ids())
    print(lib.send_http_req())
