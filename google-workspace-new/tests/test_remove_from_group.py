"""Unit tests for remove_from_group function."""

import unittest
from unittest.mock import Mock, patch
import sys
import os

# Add the function directory to the path
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', 'functions', 'remove_from_group'))
sys.path.insert(0, os.path.dirname(__file__))

from main import (
    remove_from_group_handler,
    Credentials,
    get_user,
    remove_from_group
)
from conftest import (
    get_mock_env_vars,
    get_mock_admin_service,
    create_mock_flask_request,
    get_sample_group_data
)


class TestRemoveFromGroupHandler(unittest.TestCase):
    """Test the main handler function."""
    
    def setUp(self):
        """Set up test fixtures."""
        self.mock_admin_service = get_mock_admin_service()
        self.sample_group_data = get_sample_group_data()
    
    def test_successful_remove_from_group(self):
        """Test successful removing user from group."""
        request = create_mock_flask_request(self.sample_group_data)
        
        with get_mock_env_vars():
            with patch('main.Credentials') as mock_creds_class:
                mock_creds = Mock()
                mock_creds.build.return_value = self.mock_admin_service
                mock_creds_class.return_value = mock_creds
                
                with patch('main.get_user') as mock_get_user, \
                     patch('main.remove_from_group') as mock_remove_from_group:
                    
                    mock_get_user.return_value = {'primaryEmail': 'test@example.com'}
                    
                    # Execute
                    response = remove_from_group_handler(request)
                    
                    # Assert
                    self.assertEqual(response.status_code, 200)
                    self.assertIn('removed from group successfully', response.get_data(as_text=True))
                    mock_remove_from_group.assert_called_once_with(
                        'test@example.com',
                        'test-group@example.com',
                        self.mock_admin_service
                    )
    
    def test_user_not_found(self):
        """Test when user does not exist."""
        request = create_mock_flask_request(self.sample_group_data)
        
        with get_mock_env_vars():
            with patch('main.Credentials') as mock_creds_class:
                mock_creds = Mock()
                mock_creds.build.return_value = self.mock_admin_service
                mock_creds_class.return_value = mock_creds
                
                with patch('main.get_user') as mock_get_user:
                    mock_get_user.return_value = None
                    
                    # Execute
                    response = remove_from_group_handler(request)
                    
                    # Assert
                    self.assertEqual(response.status_code, 400)
                    self.assertIn('does not exist', response.get_data(as_text=True))
    
    def test_missing_parameters(self):
        """Test missing required parameters."""
        incomplete_data = {'user_email': 'test@example.com'}  # Missing group_email
        request = create_mock_flask_request(incomplete_data)
        
        # Execute
        response = remove_from_group_handler(request)
        
        # Assert
        self.assertEqual(response.status_code, 400)
        self.assertIn('Missing parameter', response.get_data(as_text=True))


class TestRemoveFromGroupFunction(unittest.TestCase):
    """Test the remove_from_group helper function."""
    
    def setUp(self):
        """Set up test fixtures."""
        self.mock_admin_service = get_mock_admin_service()
    
    def test_remove_from_group_success(self):
        """Test successful removing user from group."""
        remove_from_group(
            'test@example.com',
            'test-group@example.com',
            self.mock_admin_service
        )
        
        self.mock_admin_service.members().delete.assert_called_once_with(
            groupKey='test-group@example.com',
            memberKey='test@example.com'
        )


class TestSecurityScenarios(unittest.TestCase):
    """Test security-related scenarios."""
    
    def setUp(self):
        """Set up test fixtures."""
        self.mock_admin_service = get_mock_admin_service()
    
    def test_unauthorized_group_removal(self):
        """Test unauthorized group removal."""
        request_data = {
            'user_email': 'test@example.com',
            'group_email': 'admin-group@example.com'  # Potentially restricted group
        }
        request = create_mock_flask_request(request_data)
        
        with get_mock_env_vars():
            with patch('main.Credentials') as mock_creds_class:
                mock_creds = Mock()
                mock_creds.build.return_value = self.mock_admin_service
                mock_creds_class.return_value = mock_creds
                
                with patch('main.get_user') as mock_get_user, \
                     patch('main.remove_from_group') as mock_remove_from_group:
                    
                    mock_get_user.return_value = {'primaryEmail': 'test@example.com'}
                    mock_remove_from_group.side_effect = Exception("Access denied to group")
                    
                    # Execute
                    response = remove_from_group_handler(request)
                    
                    # Assert
                    self.assertEqual(response.status_code, 400)
                    self.assertIn('Failed to remove user from group', response.get_data(as_text=True))


if __name__ == '__main__':
    unittest.main()