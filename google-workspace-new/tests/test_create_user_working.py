"""Working unit tests for create_user function."""

import unittest
from unittest.mock import Mock, patch
import sys
import os

# Clear any conflicting imports
if 'main' in sys.modules:
    del sys.modules['main']

# Add the specific function directory to the path
function_path = os.path.join(os.path.dirname(__file__), '..', 'functions', 'create_user')
sys.path.insert(0, function_path)

# Import the function module
try:
    import main as create_user_main
except ImportError as e:
    print(f"Import error: {e}")
    create_user_main = None

# Add conftest path
sys.path.insert(0, os.path.dirname(__file__))
import conftest


class TestCreateUserHandlerWorking(unittest.TestCase):
    """Test the create_user handler function."""
    
    def setUp(self):
        """Set up test fixtures."""
        if create_user_main is None:
            self.skipTest("Could not import create_user main module")
        
        self.mock_admin_service = conftest.get_mock_admin_service()
        self.sample_user_data = conftest.get_sample_user_data()
    
    def test_handler_exists(self):
        """Test that the handler function exists."""
        self.assertTrue(hasattr(create_user_main, 'create_user_handler'))
    
    def test_credentials_class_exists(self):
        """Test that the Credentials class exists."""
        self.assertTrue(hasattr(create_user_main, 'Credentials'))
    
    def test_helper_functions_exist(self):
        """Test that helper functions exist."""
        self.assertTrue(hasattr(create_user_main, 'get_user'))
        self.assertTrue(hasattr(create_user_main, 'create_user'))
    
    def test_missing_parameters(self):
        """Test missing required parameters."""
        if create_user_main is None:
            self.skipTest("Could not import create_user main module")
            
        incomplete_data = {'user_email': 'test@example.com'}  # Missing other required fields
        request = conftest.create_mock_flask_request(incomplete_data)
        
        # Execute
        response = create_user_main.create_user_handler(request)
        
        # Assert - response is a dict, not a Flask Response
        self.assertIsInstance(response, dict)
        self.assertEqual(response.get('code'), 400)
        self.assertIn('Missing parameter', response.get('message', ''))
    
    def test_successful_user_creation_mocked(self):
        """Test successful user creation with full mocking."""
        if create_user_main is None:
            self.skipTest("Could not import create_user main module")
            
        request = conftest.create_mock_flask_request(self.sample_user_data)
        
        with conftest.get_mock_env_vars():
            with patch.object(create_user_main, 'Credentials') as mock_creds_class:
                mock_creds = Mock()
                mock_creds.build.return_value = self.mock_admin_service
                mock_creds_class.return_value = mock_creds
                
                with patch.object(create_user_main, 'get_user') as mock_get_user, \
                     patch.object(create_user_main, 'create_user') as mock_create_user:
                    
                    mock_get_user.return_value = None  # User doesn't exist
                    
                    # Execute
                    response = create_user_main.create_user_handler(request)
                    
                    # Assert - response is a dict, not a Flask Response
                    self.assertIsInstance(response, dict)
                    self.assertEqual(response.get('code'), 200)
                    self.assertIn('created successfully', response.get('message', ''))
                    mock_create_user.assert_called_once_with(
                        'test@example.com',
                        'temp_password123',
                        'Test',
                        'User',
                        '/Test OU',
                        self.mock_admin_service
                    )


if __name__ == '__main__':
    unittest.main()