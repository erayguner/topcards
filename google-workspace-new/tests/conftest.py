"""Shared test utilities and mocks for Google Workspace function tests."""

from unittest.mock import Mock, MagicMock, patch
import os
import json
from flask import Flask, Request


def get_mock_env_vars():
    """Mock environment variables for testing."""
    return patch.dict(os.environ, {
        'GROUP_LIST_SUBJECT': 'admin@example.com',
        'SPREADSHEET_ID': 'test-spreadsheet-id',
        'AWS_ACCESS_KEY_ID': 'test-aws-key',
        'AWS_SECRET_ACCESS_KEY': 'test-aws-secret',
        'API_URL': 'https://test-api.example.com'
    })


def get_mock_google_auth():
    """Mock Google authentication and service creation."""
    mock_creds = Mock()
    mock_creds.service_account_email = 'test@example.iam.gserviceaccount.com'
    
    mock_signer_instance = Mock()
    mock_sa_creds_instance = Mock()
    
    return {
        'creds': mock_creds,
        'signer': mock_signer_instance,
        'sa_creds': mock_sa_creds_instance,
        'patches': [
            patch('google.auth.default', return_value=(mock_creds, 'test-project')),
            patch('google.auth.iam.Signer', return_value=mock_signer_instance),
            patch('google.oauth2.service_account.Credentials', return_value=mock_sa_creds_instance),
            patch('googleapiclient.discovery.build')
        ]
    }


def get_mock_admin_service():
    """Mock Google Admin SDK service."""
    service = Mock()
    
    # Mock users API
    service.users.return_value.get.return_value.execute.return_value = {
        'primaryEmail': 'test@example.com',
        'name': {'givenName': 'Test', 'familyName': 'User'},
        'suspended': False
    }
    service.users.return_value.insert.return_value.execute.return_value = {}
    service.users.return_value.update.return_value.execute.return_value = {}
    service.users.return_value.delete.return_value.execute.return_value = {}
    
    # Mock groups API
    service.groups.return_value.get.return_value.execute.return_value = {
        'email': 'test-group@example.com',
        'name': 'Test Group'
    }
    
    # Mock members API
    service.members.return_value.list.return_value.execute.return_value = {
        'members': [{'email': 'member1@example.com'}, {'email': 'member2@example.com'}]
    }
    service.members.return_value.insert.return_value.execute.return_value = {}
    service.members.return_value.delete.return_value.execute.return_value = {}
    
    return service


def get_mock_license_service():
    """Mock Google Licensing service."""
    service = Mock()
    service.licenseAssignments.return_value.insert.return_value.execute.return_value = {}
    service.licenseAssignments.return_value.delete.return_value.execute.return_value = {}
    return service


def get_mock_sheets_service():
    """Mock Google Sheets service."""
    service = Mock()
    service.spreadsheets.return_value.values.return_value.get.return_value.execute.return_value = {
        'values': [
            ['Date', 'Google Email', 'AWS Username', 'GitHub Username'],
            ['2023-01-01', 'user1@example.com', 'aws_user1', 'gh_user1'],
            ['2023-12-31', 'user2@example.com', 'aws_user2', 'gh_user2']
        ]
    }
    return service


def create_mock_flask_request(json_data=None, method='POST'):
    """Create a mock Flask request object."""
    request = Mock(spec=Request)
    request.json = json_data or {}
    request.get_json.return_value = json_data or {}
    request.method = method
    return request


def get_sample_user_data():
    """Sample user data for testing."""
    return {
        'user_email': 'test@example.com',
        'user_password': 'temp_password123',
        'user_first_name': 'Test',
        'user_last_name': 'User',
        'org_unit_path': '/Test OU'
    }


def get_sample_group_data():
    """Sample group data for testing."""
    return {
        'user_email': 'test@example.com',
        'group_email': 'test-group@example.com'
    }


def get_sample_license_data():
    """Sample license data for testing."""
    return {
        'user_email': 'test@example.com',
        'product_id': 'Google-Apps',
        'license_sku': 'Google-Apps-For-Business'
    }


def get_mock_aws_session():
    """Mock AWS session and SigV4Auth."""
    mock_session_instance = Mock()
    mock_session_instance.get_credentials.return_value = Mock()
    
    mock_sig_auth_instance = Mock()
    
    mock_request = Mock()
    mock_request.url = 'https://test-api.example.com'
    mock_request.headers = {}
    mock_request.auth_path = None
    
    return {
        'session': mock_session_instance,
        'sig_auth': mock_sig_auth_instance,
        'request': mock_request,
        'patches': [
            patch('boto3.Session', return_value=mock_session_instance),
            patch('botocore.auth.SigV4Auth', return_value=mock_sig_auth_instance),
            patch('botocore.awsrequest.AWSRequest', return_value=mock_request)
        ]
    }


def get_mock_requests():
    """Mock requests library for HTTP calls."""
    mock_response = Mock()
    mock_response.status_code = 200
    mock_response.json.return_value = {'status': 'success'}
    mock_response.text = 'Success'
    
    return {
        'response': mock_response,
        'patch': patch('requests.delete', return_value=mock_response)
    }


def create_mock_flask_app():
    """Create a mock Flask application context for testing."""
    app = Flask(__name__)
    return app