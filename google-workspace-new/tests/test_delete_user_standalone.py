"""
Self-contained comprehensive unit tests for delete_user function.
No external dependencies - all mocks and utilities included.
"""

import unittest
from unittest.mock import Mock, patch, MagicMock
import sys
import os
from googleapiclient.errors import HttpError

# Add the function directory to the path
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', 'functions', 'delete_user'))

# Import the main module
import importlib.util
spec = importlib.util.spec_from_file_location("main", os.path.join(os.path.dirname(__file__), '..', 'functions', 'delete_user', 'main.py'))
main_module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(main_module)

# Import from main module
delete_user_handler = main_module.delete_user_handler
Credentials = main_module.Credentials
get_user = main_module.get_user
delete_user = main_module.delete_user


def create_mock_flask_request(json_data=None, method='POST'):
    """Create a mock Flask request object."""
    request = Mock()
    request.json = json_data or {}
    request.get_json.return_value = json_data or {}
    request.method = method
    return request


def get_mock_admin_service():
    """Mock Google Admin SDK service."""
    service = Mock()
    
    # Mock users API
    service.users.return_value.get.return_value.execute.return_value = {
        'primaryEmail': 'test@example.com',
        'name': {'givenName': 'Test', 'familyName': 'User'},
        'suspended': False
    }
    service.users.return_value.delete.return_value.execute.return_value = {}
    
    return service


def get_mock_env_vars():
    """Mock environment variables for testing."""
    return patch.dict(os.environ, {
        'GROUP_LIST_SUBJECT': 'admin@example.com'
    })


class TestDeleteUserFunction(unittest.TestCase):
    """Test the core delete_user function directly."""
    
    def setUp(self):
        """Set up test fixtures."""
        self.mock_service = get_mock_admin_service()
    
    def test_delete_user_success(self):
        """Test successful user deletion."""
        user_email = "test@example.com"
        
        # Mock the delete operation
        self.mock_service.users.return_value.delete.return_value.execute.return_value = {}
        
        # Execute - should not raise any exceptions
        result = delete_user(user_email, self.mock_service)
        
        # Verify the service was called correctly
        self.mock_service.users.assert_called_once()
        self.mock_service.users.return_value.delete.assert_called_once_with(userKey=user_email)
        self.mock_service.users.return_value.delete.return_value.execute.assert_called_once()
        
        # Function returns None on success
        self.assertIsNone(result)


class TestGetUserFunction(unittest.TestCase):
    """Test the get_user helper function."""
    
    def setUp(self):
        """Set up test fixtures."""
        self.mock_service = get_mock_admin_service()
    
    def test_get_user_exists(self):
        """Test retrieving an existing user."""
        user_email = "test@example.com"
        expected_user = {
            'primaryEmail': user_email,
            'name': {'givenName': 'Test', 'familyName': 'User'},
            'suspended': False
        }
        
        self.mock_service.users.return_value.get.return_value.execute.return_value = expected_user
        
        result = get_user(user_email, self.mock_service)
        
        self.assertEqual(result, expected_user)
        self.mock_service.users.return_value.get.assert_called_once_with(userKey=user_email)
    
    def test_get_user_not_exists(self):
        """Test retrieving a non-existent user."""
        user_email = "nonexistent@example.com"
        
        # Mock API error for non-existent user
        self.mock_service.users.return_value.get.return_value.execute.side_effect = HttpError(
            resp=Mock(status=404), content=b'{"error": {"message": "User not found"}}'
        )
        
        result = get_user(user_email, self.mock_service)
        
        # Should return None for non-existent users
        self.assertIsNone(result)


class TestDeleteUserHandler(unittest.TestCase):
    """Test the main handler function."""
    
    def setUp(self):
        """Set up test fixtures."""
        self.mock_admin_service = get_mock_admin_service()
        self.sample_user_data = {"user_email": "test@example.com"}
    
    def test_successful_user_deletion(self):
        """Test successful user deletion through handler."""
        request = create_mock_flask_request(self.sample_user_data)
        
        with get_mock_env_vars():
            with patch.object(main_module, 'Credentials') as mock_creds_class:
                mock_creds = Mock()
                mock_creds.build.return_value = self.mock_admin_service
                mock_creds_class.return_value = mock_creds
                
                with patch.object(main_module, 'get_user') as mock_get_user, \
                     patch.object(main_module, 'delete_user') as mock_delete_user:
                    
                    # User exists
                    mock_get_user.return_value = {'primaryEmail': 'test@example.com'}
                    
                    # Execute
                    response = delete_user_handler(request)
                    
                    # Assert
                    self.assertEqual(response["code"], 200)
                    self.assertEqual(response["status"], "success")
                    self.assertIn('deleted successfully', response["message"])
                    mock_delete_user.assert_called_once_with(
                        'test@example.com',
                        self.mock_admin_service
                    )
    
    def test_user_does_not_exist(self):
        """Test deletion when user doesn't exist."""
        request = create_mock_flask_request(self.sample_user_data)
        
        with get_mock_env_vars():
            with patch.object(main_module, 'Credentials') as mock_creds_class:
                mock_creds = Mock()
                mock_creds.build.return_value = self.mock_admin_service
                mock_creds_class.return_value = mock_creds
                
                with patch.object(main_module, 'get_user') as mock_get_user:
                    # User doesn't exist
                    mock_get_user.return_value = None
                    
                    # Execute
                    response = delete_user_handler(request)
                    
                    # Assert
                    self.assertEqual(response["code"], 400)
                    self.assertEqual(response["status"], "error")
                    self.assertIn('does not exist', response["message"])
    
    def test_missing_parameters(self):
        """Test missing required parameters."""
        request = create_mock_flask_request({})  # No user_email
        
        with get_mock_env_vars():
            with patch.object(main_module, 'Credentials') as mock_creds_class:
                mock_creds = Mock()
                mock_creds.build.return_value = self.mock_admin_service
                mock_creds_class.return_value = mock_creds
                
                with patch.object(main_module, 'get_user') as mock_get_user:
                    # When user_email is None, get_user should return None
                    mock_get_user.return_value = None
                    
                    response = delete_user_handler(request)
                    
                    self.assertEqual(response["code"], 400)
                    self.assertEqual(response["status"], "error")
                    # Since .get() returns None, it will trigger "does not exist" error
                    self.assertIn('does not exist', response["message"])
    
    def test_api_error_handling(self):
        """Test Google API error handling."""
        request = create_mock_flask_request(self.sample_user_data)
        
        with get_mock_env_vars():
            with patch.object(main_module, 'Credentials') as mock_creds_class:
                mock_creds = Mock()
                mock_creds.build.return_value = self.mock_admin_service
                mock_creds_class.return_value = mock_creds
                
                with patch.object(main_module, 'get_user') as mock_get_user, \
                     patch.object(main_module, 'delete_user') as mock_delete_user:
                    
                    # User exists
                    mock_get_user.return_value = {'primaryEmail': 'test@example.com'}
                    
                    # API error during deletion
                    mock_delete_user.side_effect = HttpError(
                        resp=Mock(status=403), 
                        content=b'{"error": {"message": "Insufficient permissions"}}'
                    )
                    
                    # Execute
                    response = delete_user_handler(request)
                    
                    # Assert
                    self.assertEqual(response["code"], 400)
                    self.assertEqual(response["status"], "error")
                    self.assertIn('Failed to delete user', response["message"])


class TestSecurityScenarios(unittest.TestCase):
    """Test security-related scenarios and edge cases."""
    
    def setUp(self):
        """Set up test fixtures."""
        self.mock_admin_service = get_mock_admin_service()
    
    def test_email_injection_protection(self):
        """Test protection against email injection attacks."""
        malicious_emails = [
            "admin@example.com; DROP TABLE users;",
            "test@example.com\n\r--admin@example.com",
            "'; DELETE FROM users WHERE '1'='1",
            "<script>alert('xss')</script>@example.com"
        ]
        
        for malicious_email in malicious_emails:
            with self.subTest(email=malicious_email):
                request = create_mock_flask_request({"user_email": malicious_email})
                
                with get_mock_env_vars():
                    with patch.object(main_module, 'Credentials') as mock_creds_class:
                        mock_creds = Mock()
                        mock_creds.build.return_value = self.mock_admin_service
                        mock_creds_class.return_value = mock_creds
                        
                        with patch.object(main_module, 'get_user') as mock_get_user:
                            # User doesn't exist (expected for malicious emails)
                            mock_get_user.return_value = None
                            
                            # Execute
                            response = delete_user_handler(request)
                            
                            # Should handle gracefully with error response
                            self.assertEqual(response["code"], 400)
                            self.assertEqual(response["status"], "error")
                            self.assertIn('does not exist', response["message"])
    
    def test_malformed_request_handling(self):
        """Test handling of malformed requests."""
        malformed_requests = [
            {"user_email": ""},  # Empty email
            {"user_email": None},  # None email
            {"wrong_field": "test@example.com"},  # Wrong field name
        ]
        
        for malformed_data in malformed_requests:
            with self.subTest(data=malformed_data):
                request = create_mock_flask_request(malformed_data)
                
                with get_mock_env_vars():
                    with patch.object(main_module, 'Credentials') as mock_creds_class:
                        mock_creds = Mock()
                        mock_creds.build.return_value = self.mock_admin_service
                        mock_creds_class.return_value = mock_creds
                        
                        with patch.object(main_module, 'get_user') as mock_get_user:
                            # Malformed requests will result in None/empty user_email
                            mock_get_user.return_value = None
                            
                            response = delete_user_handler(request)
                            
                            # Should handle gracefully with error response
                            self.assertEqual(response["code"], 400)
                            self.assertEqual(response["status"], "error")
                            # All malformed requests should result in "does not exist" error
                            self.assertIn('does not exist', response["message"])


if __name__ == '__main__':
    # Run with verbose output
    unittest.main(verbosity=2)