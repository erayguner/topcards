"""Unit tests for aws_leaver function."""

import unittest
from unittest.mock import Mock, patch
import sys
import os

# Add the function directory to the path
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', 'functions', 'aws_leaver'))
sys.path.insert(0, os.path.dirname(__file__))

from main import (
    aws_leaver_handler,
    send_aws_delete_request
)
from conftest import (
    get_mock_env_vars,
    get_mock_aws_session,
    get_mock_requests,
    create_mock_flask_request
)


class TestAwsLeaverHandler(unittest.TestCase):
    """Test the main handler function."""
    
    def setUp(self):
        """Set up test fixtures."""
        self.mock_aws_session = get_mock_aws_session()
        self.mock_requests = get_mock_requests()
    
    def test_successful_aws_delete_request(self):
        """Test successful AWS user deletion request."""
        request_data = {'aws_username': 'test_user'}
        request = create_mock_flask_request(request_data)
        
        with get_mock_env_vars():
            with patch('main.send_aws_delete_request') as mock_send_request:
                mock_send_request.return_value = True
                
                # Execute
                response = aws_leaver_handler(request)
                
                # Assert
                self.assertEqual(response.status_code, 200)
                self.assertIn('AWS delete request sent successfully', response.get_data(as_text=True))
                mock_send_request.assert_called_once_with('test_user')
    
    def test_missing_parameters(self):
        """Test missing required parameters."""
        request_data = {}  # Missing aws_username
        request = create_mock_flask_request(request_data)
        
        # Execute
        response = aws_leaver_handler(request)
        
        # Assert
        self.assertEqual(response.status_code, 400)
        self.assertIn('Missing parameter', response.get_data(as_text=True))
    
    def test_aws_request_failure(self):
        """Test AWS request failure."""
        request_data = {'aws_username': 'test_user'}
        request = create_mock_flask_request(request_data)
        
        with get_mock_env_vars():
            with patch('main.send_aws_delete_request') as mock_send_request:
                mock_send_request.return_value = False
                
                # Execute
                response = aws_leaver_handler(request)
                
                # Assert
                self.assertEqual(response.status_code, 400)
                self.assertIn('Failed to send AWS delete request', response.get_data(as_text=True))


class TestSendAwsDeleteRequestFunction(unittest.TestCase):
    """Test the send_aws_delete_request helper function."""
    
    def setUp(self):
        """Set up test fixtures."""
        self.mock_aws_session = get_mock_aws_session()
        self.mock_requests = get_mock_requests()
    
    def test_send_aws_delete_request_success(self):
        """Test successful AWS delete request."""
        with get_mock_env_vars():
            # Apply all patches from mock_aws_session
            patches = []
            for patch_obj in self.mock_aws_session['patches']:
                patches.append(patch_obj.__enter__())
            
            try:
                with self.mock_requests['patch']:
                    result = send_aws_delete_request('test_user')
                    
                    # Assert
                    self.assertTrue(result)
            finally:
                # Clean up patches
                for patch_obj in self.mock_aws_session['patches']:
                    patch_obj.__exit__(None, None, None)
    
    def test_send_aws_delete_request_failure(self):
        """Test AWS delete request failure."""
        with get_mock_env_vars():
            # Apply all patches from mock_aws_session
            patches = []
            for patch_obj in self.mock_aws_session['patches']:
                patches.append(patch_obj.__enter__())
            
            try:
                with patch('requests.delete') as mock_delete:
                    mock_delete.side_effect = Exception("AWS API Error")
                    
                    result = send_aws_delete_request('test_user')
                    
                    # Assert
                    self.assertFalse(result)
            finally:
                # Clean up patches
                for patch_obj in self.mock_aws_session['patches']:
                    patch_obj.__exit__(None, None, None)


class TestSecurityScenarios(unittest.TestCase):
    """Test security-related scenarios."""
    
    def setUp(self):
        """Set up test fixtures."""
        self.mock_aws_session = get_mock_aws_session()
        self.mock_requests = get_mock_requests()
    
    def test_malicious_username_injection(self):
        """Test protection against username injection attacks."""
        request_data = {'aws_username': '../admin'}  # Path traversal attempt
        request = create_mock_flask_request(request_data)
        
        with get_mock_env_vars():
            with patch('main.send_aws_delete_request') as mock_send_request:
                mock_send_request.side_effect = Exception("Invalid username format")
                
                # Execute
                response = aws_leaver_handler(request)
                
                # Assert
                self.assertEqual(response.status_code, 400)
                self.assertIn('Failed to send AWS delete request', response.get_data(as_text=True))
    
    def test_unauthorized_aws_access(self):
        """Test unauthorized AWS access."""
        request_data = {'aws_username': 'admin_user'}  # Potentially restricted user
        request = create_mock_flask_request(request_data)
        
        with get_mock_env_vars():
            with patch('main.send_aws_delete_request') as mock_send_request:
                mock_send_request.side_effect = Exception("Access denied")
                
                # Execute
                response = aws_leaver_handler(request)
                
                # Assert
                self.assertEqual(response.status_code, 400)
                self.assertIn('Failed to send AWS delete request', response.get_data(as_text=True))


if __name__ == '__main__':
    unittest.main()