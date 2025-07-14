import json
import os

import google.auth
from google.auth import iam
from google.auth.transport import requests as g_requests
from google.oauth2 import service_account
from googleapiclient.discovery import build
from flask import Request

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
            bootstrap_creds.service_account_email
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


def get_user(user_email: str, service) -> dict | None:
    """
    Return the user resource if it exists, otherwise None.
    """
    try:
        return service.users().get(userKey=user_email).execute()
    except Exception:
        return None


def create_user(
    user_email: str,
    user_password: str,
    user_first_name: str,
    user_last_name: str,
    org_unit_path: str,
    service
) -> None:
    """
    Inserts a new Google Workspace user.
    """
    body = {
        "primaryEmail": user_email,
        "password": user_password,
        "changePasswordAtNextLogin": True,
        "name": {
            "givenName": user_first_name,
            "familyName": user_last_name
        },
        "orgUnitPath": org_unit_path,
    }
    service.users().insert(body=body).execute()


def create_user_handler(request: Request):
    """
    Cloud Run (or Cloud Function) HTTP entry-point to create a user.
    Expects JSON payload with keys:
      - user_email
      - user_password
      - user_first_name
      - user_last_name
      - org_unit_path
    """
    try:
        payload = request.get_json(force=True)
        email      = payload["user_email"]
        password   = payload["user_password"]
        first_name = payload["user_first_name"]
        last_name  = payload["user_last_name"]
        ou_path    = payload["org_unit_path"]

        # build Admin SDK Directory service
        creds   = Credentials()
        service = creds.build("admin", "directory_v1")

        # ensure user does not already exist
        if get_user(email, service):
            raise ValueError(f"User {email} already exists.")

        # create the user
        create_user(email, password, first_name, last_name, ou_path, service)

        return {"status": "success", "message": "User created successfully.", "code": 200}

    except KeyError as ke:
        return {"status": "error", "message": f"Missing parameter: {ke}", "code": 400}
    except Exception as e:
        return {"status": "error", "message": f"Failed to create user. Error: {e}", "code": 400}
