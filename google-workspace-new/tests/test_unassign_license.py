"""Unit tests for unassign_license function."""

import unittest
from unittest.mock import Mock, patch
import sys
import os

# Add the function directory to the path
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', 'functions', 'unassign_license'))
sys.path.insert(0, os.path.dirname(__file__))

from main import (
    unassign_license_handler,
    Credentials,
    get_user,
    unassign_license
)
from conftest import (
    get_mock_env_vars,
    get_mock_admin_service,
    get_mock_license_service,
    create_mock_flask_request,
    get_sample_license_data
)


class TestUnassignLicenseHandler(unittest.TestCase):
    """Test the main handler function."""
    
    def setUp(self):
        """Set up test fixtures."""
        self.mock_admin_service = get_mock_admin_service()
        self.mock_license_service = get_mock_license_service()
        self.sample_license_data = get_sample_license_data()
    
    def test_successful_license_unassignment(self):
        """Test successful license unassignment."""
        request = create_mock_flask_request(self.sample_license_data)
        
        with get_mock_env_vars():
            with patch('main.Credentials') as mock_creds_class:
                mock_creds = Mock()
                mock_creds.build.side_effect = [self.mock_admin_service, self.mock_license_service]
                mock_creds_class.return_value = mock_creds
                
                with patch('main.get_user') as mock_get_user, \
                     patch('main.unassign_license') as mock_unassign_license:
                    
                    mock_get_user.return_value = {'primaryEmail': 'test@example.com'}
                    
                    # Execute
                    response = unassign_license_handler(request)
                    
                    # Assert
                    self.assertEqual(response.status_code, 200)
                    self.assertIn('unassigned successfully', response.get_data(as_text=True))
                    mock_unassign_license.assert_called_once_with(
                        'test@example.com',
                        'Google-Apps',
                        'Google-Apps-For-Business',
                        self.mock_license_service
                    )
    
    def test_user_not_found(self):
        """Test when user does not exist."""
        request = create_mock_flask_request(self.sample_license_data)
        
        with get_mock_env_vars():
            with patch('main.Credentials') as mock_creds_class:
                mock_creds = Mock()
                mock_creds.build.return_value = self.mock_admin_service
                mock_creds_class.return_value = mock_creds
                
                with patch('main.get_user') as mock_get_user:
                    mock_get_user.return_value = None
                    
                    # Execute
                    response = unassign_license_handler(request)
                    
                    # Assert
                    self.assertEqual(response.status_code, 400)
                    self.assertIn('does not exist', response.get_data(as_text=True))
    
    def test_missing_parameters(self):
        """Test missing required parameters."""
        incomplete_data = {'user_email': 'test@example.com'}  # Missing license info
        request = create_mock_flask_request(incomplete_data)
        
        # Execute
        response = unassign_license_handler(request)
        
        # Assert
        self.assertEqual(response.status_code, 400)
        self.assertIn('Missing parameter', response.get_data(as_text=True))


class TestUnassignLicenseFunction(unittest.TestCase):
    """Test the unassign_license helper function."""
    
    def setUp(self):
        """Set up test fixtures."""
        self.mock_license_service = get_mock_license_service()
    
    def test_unassign_license_success(self):
        """Test successful license unassignment."""
        unassign_license(
            'test@example.com',
            'Google-Apps',
            'Google-Apps-For-Business',
            self.mock_license_service
        )
        
        self.mock_license_service.licenseAssignments().delete.assert_called_once_with(
            productId='Google-Apps',
            skuId='Google-Apps-For-Business',
            userId='test@example.com'
        )


class TestSecurityScenarios(unittest.TestCase):
    """Test security-related scenarios."""
    
    def setUp(self):
        """Set up test fixtures."""
        self.mock_admin_service = get_mock_admin_service()
        self.mock_license_service = get_mock_license_service()
    
    def test_unauthorized_license_unassignment(self):
        """Test unauthorized license unassignment."""
        request_data = {
            'user_email': 'test@example.com',
            'product_id': 'Premium-License',  # Potentially restricted license
            'license_sku': 'Premium-Suite'
        }
        request = create_mock_flask_request(request_data)
        
        with get_mock_env_vars():
            with patch('main.Credentials') as mock_creds_class:
                mock_creds = Mock()
                mock_creds.build.side_effect = [self.mock_admin_service, self.mock_license_service]
                mock_creds_class.return_value = mock_creds
                
                with patch('main.get_user') as mock_get_user, \
                     patch('main.unassign_license') as mock_unassign_license:
                    
                    mock_get_user.return_value = {'primaryEmail': 'test@example.com'}
                    mock_unassign_license.side_effect = Exception("License cannot be unassigned")
                    
                    # Execute
                    response = unassign_license_handler(request)
                    
                    # Assert
                    self.assertEqual(response.status_code, 400)
                    self.assertIn('Failed to unassign license', response.get_data(as_text=True))


if __name__ == '__main__':
    unittest.main()