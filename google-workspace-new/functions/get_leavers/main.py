""" This is a Docstring """

import os
from datetime import datetime

import google.auth
from google.auth import iam
from google.auth.transport import requests as g_requests
from google.oauth2 import service_account
from googleapiclient.discovery import build


SPREADSHEET_ID = os.environ.get("SPREADSHEET_ID")
RANGE_NAME = "Sheet1!A:D"


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


def get_leavers_handler(_):
    """
    Matches leaver dates with today's date and returns lists of user emails for each category.

    Args:
        event: The event data (unused).
        context: The event context (unused).
    """

    today_date = datetime.now()

    creds = Credentials()
    creds = creds.creds
    service = build("sheets", "v4", credentials=creds)

    sheet = service.spreadsheets()
    result = (
        sheet.values().get(spreadsheetId=SPREADSHEET_ID, range=RANGE_NAME).execute()
    )
    values = result.get("values", [])

    google_workspace_leavers = []
    aws_leavers = []
    github_leavers = []

    for i, row in enumerate(values):
        if i == 0:
            continue

        leaver_date = datetime.strptime(row[0], "%Y-%m-%d")
        if leaver_date >= today_date:
            continue

        if len(row) > 1 and row[1]:
            google_workspace_leavers.append(row[1])

        if len(row) > 2 and row[2]:
            aws_leavers.append(row[2])

        if len(row) > 3 and row[3]:
            github_leavers.append(row[3])

    print("Google Workspace Leavers:", google_workspace_leavers)
    print("AWS Leavers:", aws_leavers)
    print("GitHub Leavers:", github_leavers)

    return {
        "google_workspace_leavers": google_workspace_leavers,
        "aws_leavers": aws_leavers,
        "github_leavers": github_leavers,
    }
