"""Cloud function to call AWS ICEMan API."""

import os
import json
import requests
import boto3
from botocore.auth import SigV4Auth
from botocore.awsrequest import AWSRequest


def aws_leaver_handler(request):
    """
    Function to invoke AWS ICEMan API to remove a user from all groups.

    Args:
        request (dict[str, str]): Request body.

    Returns:
        dict[str, Any]: The request response.
    """

    aws_access_key_id = os.environ["AWS_ACCESS_KEY_ID"]
    aws_secret_access_key = os.environ["AWS_SECRET_ACCESS_KEY"]
    api_url = os.environ["API_URL"]
    region = "eu-west-2"

    username = request.json.get("username")
    payload = {"username": username}

    # Prepare the AWS request
    aws_request = AWSRequest(method="DELETE", url=api_url, data=json.dumps(payload))
    SigV4Auth(
        boto3.Session(
            aws_access_key_id=aws_access_key_id,
            aws_secret_access_key=aws_secret_access_key,
        ).get_credentials(),
        "execute-api",
        region,
    ).add_auth(aws_request)

    # Send the request
    response = requests.delete(
        aws_request.url,
        auth=aws_request.auth_path,
        headers=aws_request.headers,
        data=json.dumps(payload),
        timeout=10,
    )

    # Process the response
    if response.status_code == 200:
        return response.json()

    return {"status_code": response.status_code, "error": response.text}
