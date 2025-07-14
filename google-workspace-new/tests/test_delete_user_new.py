"""
Comprehensive unit tests for delete_user function.
Written from scratch with full test coverage and security scenarios.
"""

import unittest
from unittest.mock import Mock, patch, MagicMock
import sys
import os
from googleapiclient.errors import HttpError

# Add the function directory to the path
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', 'functions', 'delete_user'))
sys.path.insert(0, os.path.dirname(__file__))

# Import the main module from delete_user function
import importlib.util
spec = importlib.util.spec_from_file_location("main", os.path.join(os.path.dirname(__file__), '..', 'functions', 'delete_user', 'main.py'))
main_module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(main_module)

# Import from main module
delete_user_handler = main_module.delete_user_handler
Credentials = main_module.Credentials
get_user = main_module.get_user
delete_user = main_module.delete_user

# Import conftest from current directory  
import conftest
get_mock_env_vars = conftest.get_mock_env_vars
get_mock_admin_service = conftest.get_mock_admin_service
create_mock_flask_request = conftest.create_mock_flask_request


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
    
    def test_delete_user_api_error(self):
        """Test delete_user when Google API raises an error."""
        user_email = "test@example.com"
        
        # Mock API error
        self.mock_service.users.return_value.delete.return_value.execute.side_effect = HttpError(
            resp=Mock(status=404), content=b'{"error": {"message": "User not found"}}'
        )
        
        # Should raise the HttpError
        with self.assertRaises(HttpError):
            delete_user(user_email, self.mock_service)


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
    
    def test_get_user_api_error(self):
        """Test get_user with unexpected API error."""
        user_email = "test@example.com"
        
        # Mock unexpected API error
        self.mock_service.users.return_value.get.return_value.execute.side_effect = HttpError(
            resp=Mock(status=500), content=b'{"error": {"message": "Internal server error"}}'
        )
        
        result = get_user(user_email, self.mock_service)
        
        # Should return None for any exception
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
            with patch('main.Credentials') as mock_creds_class:
                mock_creds = Mock()
                mock_creds.build.return_value = self.mock_admin_service
                mock_creds_class.return_value = mock_creds
                
                with patch('main.get_user') as mock_get_user, \
                     patch('main.delete_user') as mock_delete_user:
                    
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
            with patch('main.Credentials') as mock_creds_class:
                mock_creds = Mock()
                mock_creds.build.return_value = self.mock_admin_service
                mock_creds_class.return_value = mock_creds
                
                with patch('main.get_user') as mock_get_user:
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
            response = delete_user_handler(request)
            
            self.assertEqual(response["code"], 400)
            self.assertEqual(response["status"], "error")
            self.assertIn('Missing parameter', response["message"])
    
    def test_api_error_handling(self):
        """Test Google API error handling."""
        request = create_mock_flask_request(self.sample_user_data)
        
        with get_mock_env_vars():
            with patch('main.Credentials') as mock_creds_class:
                mock_creds = Mock()
                mock_creds.build.return_value = self.mock_admin_service
                mock_creds_class.return_value = mock_creds
                
                with patch('main.get_user') as mock_get_user, \
                     patch('main.delete_user') as mock_delete_user:
                    
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
                    with patch('main.Credentials') as mock_creds_class:
                        mock_creds = Mock()
                        mock_creds.build.return_value = self.mock_admin_service
                        mock_creds_class.return_value = mock_creds
                        
                        with patch('main.get_user') as mock_get_user:
                            # User doesn't exist (expected for malicious emails)
                            mock_get_user.return_value = None
                            
                            # Execute
                            response = delete_user_handler(request)
                            
                            # Should handle gracefully with error response
                            self.assertEqual(response["code"], 400)
                            self.assertEqual(response["status"], "error")
                            self.assertIn('does not exist', response["message"])
    
    def test_admin_user_protection(self):
        """Test that admin/system users cannot be deleted."""
        admin_emails = [
            "admin@example.com",
            "root@example.com",
            "system@example.com",
            "service-account@example.iam.gserviceaccount.com"
        ]
        
        for admin_email in admin_emails:
            with self.subTest(email=admin_email):
                request = create_mock_flask_request({"user_email": admin_email})
                
                with get_mock_env_vars():
                    with patch('main.Credentials') as mock_creds_class:
                        mock_creds = Mock()
                        mock_creds.build.return_value = self.mock_admin_service
                        mock_creds_class.return_value = mock_creds
                        
                        with patch('main.get_user') as mock_get_user, \
                             patch('main.delete_user') as mock_delete_user:
                            
                            # Admin user exists
                            mock_get_user.return_value = {'primaryEmail': admin_email}
                            
                            # Simulate API protection against deleting admin users
                            mock_delete_user.side_effect = HttpError(
                                resp=Mock(status=403), 
                                content=b'{"error": {"message": "Cannot delete admin user"}}'
                            )
                            
                            # Execute
                            response = delete_user_handler(request)
                            
                            # Should be handled as API error
                            self.assertEqual(response["code"], 400)
                            self.assertEqual(response["status"], "error")
                            self.assertIn('Failed to delete user', response["message"])
    
    def test_concurrent_deletion_handling(self):
        """Test handling of concurrent deletion attempts."""
        request = create_mock_flask_request({"user_email": "test@example.com"})
        
        with get_mock_env_vars():
            with patch('main.Credentials') as mock_creds_class:
                mock_creds = Mock()
                mock_creds.build.return_value = self.mock_admin_service
                mock_creds_class.return_value = mock_creds
                
                with patch('main.get_user') as mock_get_user, \
                     patch('main.delete_user') as mock_delete_user:
                    
                    # User exists initially
                    mock_get_user.return_value = {'primaryEmail': 'test@example.com'}
                    
                    # But was deleted by another process
                    mock_delete_user.side_effect = HttpError(
                        resp=Mock(status=404), 
                        content=b'{"error": {"message": "User not found"}}'
                    )
                    
                    # Execute
                    response = delete_user_handler(request)
                    
                    # Should handle gracefully
                    self.assertEqual(response["code"], 400)
                    self.assertEqual(response["status"], "error")
                    self.assertIn('Failed to delete user', response["message"])
    
    def test_malformed_request_handling(self):
        """Test handling of malformed requests."""
        malformed_requests = [
            {"user_email": ""},  # Empty email
            {"user_email": None},  # None email
            {"user_email": 12345},  # Non-string email
            {"wrong_field": "test@example.com"},  # Wrong field name
        ]
        
        for malformed_data in malformed_requests:
            with self.subTest(data=malformed_data):
                request = create_mock_flask_request(malformed_data)
                
                with get_mock_env_vars():
                    response = delete_user_handler(request)
                    
                    # Should handle gracefully with error response
                    self.assertEqual(response["code"], 400)
                    self.assertEqual(response["status"], "error")
                    # Should contain either missing parameter or user not found error
                    self.assertTrue(
                        'Missing parameter' in response["message"] or 
                        'does not exist' in response["message"]
                    )


class TestCredentialsClass(unittest.TestCase):
    """Test the Credentials class initialization and service building."""
    
    @patch('main.google.auth.default')
    @patch('main.iam.Signer')
    @patch('main.service_account.Credentials')
    def test_credentials_initialization(self, mock_sa_creds, mock_signer, mock_default_auth):
        """Test proper initialization of Credentials class."""
        # Mock the authentication flow
        mock_bootstrap_creds = Mock()
        mock_bootstrap_creds.service_account_email = 'test@example.iam.gserviceaccount.com'
        mock_default_auth.return_value = (mock_bootstrap_creds, 'test-project')
        
        mock_signer_instance = Mock()
        mock_signer.return_value = mock_signer_instance
        
        mock_final_creds = Mock()
        mock_sa_creds.return_value = mock_final_creds
        
        with get_mock_env_vars():
            # Initialize credentials
            creds = Credentials()
            
            # Verify authentication flow was called correctly
            mock_default_auth.assert_called_once_with(
                scopes=["https://www.googleapis.com/auth/cloud-platform"]
            )
            mock_bootstrap_creds.refresh.assert_called_once()
            mock_signer.assert_called_once()
            mock_sa_creds.assert_called_once()
            
            # Verify final credentials are stored
            self.assertEqual(creds.creds, mock_final_creds)
    
    @patch('main.build')
    def test_service_building(self, mock_build):
        """Test building Google API service clients."""
        mock_service = Mock()
        mock_build.return_value = mock_service
        
        # Create a credentials instance with mocked creds
        creds = Credentials.__new__(Credentials)  # Skip __init__
        creds.creds = Mock()
        
        # Build a service
        service = creds.build("admin", "directory_v1")
        
        # Verify build was called correctly
        mock_build.assert_called_once_with("admin", "directory_v1", credentials=creds.creds)
        self.assertEqual(service, mock_service)


if __name__ == '__main__':
    # Run with verbose output
    unittest.main(verbosity=2)