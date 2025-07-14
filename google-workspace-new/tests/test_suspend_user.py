"""Unit tests for suspend_user function."""

import unittest
from unittest.mock import Mock, patch
import sys
import os

# Add the function directory to the path
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', 'functions', 'suspend_user'))
sys.path.insert(0, os.path.dirname(__file__))

from main import (
    suspend_user_handler,
    Credentials,
    get_user,
    suspend_user
)
from conftest import (
    get_mock_env_vars,
    get_mock_admin_service,
    create_mock_flask_request
)


class TestSuspendUserHandler(unittest.TestCase):
    """Test the main handler function."""
    
    def setUp(self):
        """Set up test fixtures."""
        self.mock_admin_service = get_mock_admin_service()
    
    def test_successful_user_suspension(self):
        """Test successful user suspension."""
        request_data = {'user_email': 'test@example.com'}
        request = create_mock_flask_request(request_data)
        
        with get_mock_env_vars():
            with patch('main.Credentials') as mock_creds_class:
                mock_creds = Mock()
                mock_creds.build.return_value = self.mock_admin_service
                mock_creds_class.return_value = mock_creds
                
                with patch('main.get_user') as mock_get_user, \
                     patch('main.suspend_user') as mock_suspend_user:
                    
                    mock_get_user.return_value = {'primaryEmail': 'test@example.com', 'suspended': False}
                    
                    # Execute
                    response = suspend_user_handler(request)
                    
                    # Assert
                    self.assertEqual(response.status_code, 200)
                    self.assertIn('suspended successfully', response.get_data(as_text=True))
                    mock_suspend_user.assert_called_once_with('test@example.com', self.mock_admin_service)
    
    def test_user_not_found(self):
        """Test when user does not exist."""
        request_data = {'user_email': 'nonexistent@example.com'}
        request = create_mock_flask_request(request_data)
        
        with get_mock_env_vars():
            with patch('main.Credentials') as mock_creds_class:
                mock_creds = Mock()
                mock_creds.build.return_value = self.mock_admin_service
                mock_creds_class.return_value = mock_creds
                
                with patch('main.get_user') as mock_get_user:
                    mock_get_user.return_value = None
                    
                    # Execute
                    response = suspend_user_handler(request)
                    
                    # Assert
                    self.assertEqual(response.status_code, 400)
                    self.assertIn('does not exist', response.get_data(as_text=True))
    
    def test_missing_parameters(self):
        """Test missing required parameters."""
        request_data = {}  # Missing user_email
        request = create_mock_flask_request(request_data)
        
        # Execute
        response = suspend_user_handler(request)
        
        # Assert
        self.assertEqual(response.status_code, 400)
        self.assertIn('Missing parameter', response.get_data(as_text=True))
    
    def test_user_already_suspended(self):
        """Test when user is already suspended."""
        request_data = {'user_email': 'test@example.com'}
        request = create_mock_flask_request(request_data)
        
        with get_mock_env_vars():
            with patch('main.Credentials') as mock_creds_class:
                mock_creds = Mock()
                mock_creds.build.return_value = self.mock_admin_service
                mock_creds_class.return_value = mock_creds
                
                with patch('main.get_user') as mock_get_user:
                    mock_get_user.return_value = {'primaryEmail': 'test@example.com', 'suspended': True}
                    
                    # Execute
                    response = suspend_user_handler(request)
                    
                    # Assert
                    self.assertEqual(response.status_code, 400)
                    self.assertIn('already suspended', response.get_data(as_text=True))


class TestSuspendUserFunction(unittest.TestCase):
    """Test the suspend_user helper function."""
    
    def setUp(self):
        """Set up test fixtures."""
        self.mock_admin_service = get_mock_admin_service()
    
    def test_suspend_user_success(self):
        """Test successful user suspension."""
        suspend_user('test@example.com', self.mock_admin_service)
        
        expected_body = {'suspended': True}
        self.mock_admin_service.users().update.assert_called_once_with(
            userKey='test@example.com', 
            body=expected_body
        )


class TestSecurityScenarios(unittest.TestCase):
    """Test security-related scenarios."""
    
    def setUp(self):
        """Set up test fixtures."""
        self.mock_admin_service = get_mock_admin_service()
    
    def test_prevent_admin_suspension(self):
        """Test prevention of admin user suspension."""
        request_data = {'user_email': 'admin@example.com'}
        request = create_mock_flask_request(request_data)
        
        with get_mock_env_vars():
            with patch('main.Credentials') as mock_creds_class:
                mock_creds = Mock()
                mock_creds.build.return_value = self.mock_admin_service
                mock_creds_class.return_value = mock_creds
                
                with patch('main.get_user') as mock_get_user, \
                     patch('main.suspend_user') as mock_suspend_user:
                    
                    mock_get_user.return_value = {'primaryEmail': 'admin@example.com', 'suspended': False}
                    mock_suspend_user.side_effect = Exception("Cannot suspend admin user")
                    
                    # Execute
                    response = suspend_user_handler(request)
                    
                    # Assert
                    self.assertEqual(response.status_code, 400)
                    self.assertIn('Failed to suspend user', response.get_data(as_text=True))


if __name__ == '__main__':
    unittest.main()