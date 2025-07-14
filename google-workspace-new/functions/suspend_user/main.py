import json
import os

import google.auth
from google.auth import iam
from google.auth.transport import requests as g_requests
from google.oauth2 import service_account
from googleapiclient.discovery import build
from flask import Request, make_response


def suspend_user_handler(request: Request):
    try:
        user_email = request.json.get("user_email")
        creds = Credentials()
        service = creds.build("admin", "directory_v1")

        user = get_user(user_email, service)
        if not user:
            raise ValueError(f"User, {user_email} does not exist.")

        suspend_user(user_email, service)

        return make_response("User suspended successfully.", 200)
    except KeyError as ke:
        return make_response(f"Missing parameter: {ke}", 400)
    except Exception as e:
        return make_response(
            f"Failed to suspend user. Error: {e}", 400
        )


# Environment variables:
#  - GROUP_LIST_SUBJECT: the admin user to impersonate (e.g. “admin@example.com”)
#  - (other env vars if needed: BUCKET_NAME, DAYS, PROJECT, etc.)

GROUP_LIST_SUBJECT = os.getenv("GROUP_LIST_SUBJECT")
SCOPES = [
    "https://www.googleapis.com/auth/admin.directory.user",
    "https://www.googleapis.com/auth/admin.directory.group.member",
    "https://www.googleapis.com/auth/apps.licensing",
]


class Credentials:
    """
    Initialise a domain-wide-delegated service account credential
    that can impersonate a Workspace super-admin.
    """

    def __init__(self):
        # 1) Bootstrap with ADC scoped to cloud-platform
        request = g_requests.Request()
        bootstrap_creds, _ = google.auth.default(
            scopes=["https://www.googleapis.com/auth/cloud-platform"]
        )
        bootstrap_creds.refresh(request)

        # 2) Create an IAM signer from the ADC
        signer = iam.Signer(
            request,
            bootstrap_creds,
            bootstrap_creds.service_account_email,
        )

        # 3) Build the actual delegated credentials for Admin SDK
        self.creds = service_account.Credentials(
            signer=signer,
            service_account_email=bootstrap_creds.service_account_email,
            token_uri="https://accounts.google.com/o/oauth2/token",
            scopes=SCOPES,
            subject=GROUP_LIST_SUBJECT,
        )

    def build(self, service_name: str, version: str):
        """
        Helper to create an Admin SDK service client.
        """
        return build(service_name, version, credentials=self.creds)


def get_user(user_email, service):
    try:
        user = service.users().get(userKey=user_email).execute()
        return user
    except Exception:
        return None


def suspend_user(user_email, service):
    service.users().update(
        userKey=user_email, body={"suspended": True}
    ).execute()
