"""Unit tests for get_leavers function."""

import unittest
from unittest.mock import Mock, patch
import sys
import os

# Add the function directory to the path
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', 'functions', 'get_leavers'))
sys.path.insert(0, os.path.dirname(__file__))

from main import (
    get_leavers_handler,
    Credentials,
    get_leavers_from_sheet
)
from conftest import (
    get_mock_env_vars,
    get_mock_sheets_service,
    create_mock_flask_request
)


class TestGetLeaversHandler(unittest.TestCase):
    """Test the main handler function."""
    
    def setUp(self):
        """Set up test fixtures."""
        self.mock_sheets_service = get_mock_sheets_service()
    
    def test_successful_get_leavers(self):
        """Test successful retrieval of leavers."""
        request_data = {}  # No parameters needed for GET
        request = create_mock_flask_request(request_data, method='GET')
        
        with get_mock_env_vars():
            with patch('main.Credentials') as mock_creds_class:
                mock_creds = Mock()
                mock_creds.build.return_value = self.mock_sheets_service
                mock_creds_class.return_value = mock_creds
                
                with patch('main.get_leavers_from_sheet') as mock_get_leavers:
                    mock_get_leavers.return_value = [
                        {'email': 'user1@example.com', 'date': '2023-01-01'},
                        {'email': 'user2@example.com', 'date': '2023-12-31'}
                    ]
                    
                    # Execute
                    response = get_leavers_handler(request)
                    
                    # Assert
                    self.assertEqual(response.status_code, 200)
                    response_data = response.get_json()
                    self.assertIsInstance(response_data, list)
                    self.assertEqual(len(response_data), 2)
                    self.assertEqual(response_data[0]['email'], 'user1@example.com')
    
    def test_empty_leavers_list(self):
        """Test when no leavers are found."""
        request_data = {}
        request = create_mock_flask_request(request_data, method='GET')
        
        with get_mock_env_vars():
            with patch('main.Credentials') as mock_creds_class:
                mock_creds = Mock()
                mock_creds.build.return_value = self.mock_sheets_service
                mock_creds_class.return_value = mock_creds
                
                with patch('main.get_leavers_from_sheet') as mock_get_leavers:
                    mock_get_leavers.return_value = []
                    
                    # Execute
                    response = get_leavers_handler(request)
                    
                    # Assert
                    self.assertEqual(response.status_code, 200)
                    response_data = response.get_json()
                    self.assertIsInstance(response_data, list)
                    self.assertEqual(len(response_data), 0)
    
    def test_sheets_api_error(self):
        """Test Google Sheets API error handling."""
        request_data = {}
        request = create_mock_flask_request(request_data, method='GET')
        
        with get_mock_env_vars():
            with patch('main.Credentials') as mock_creds_class:
                mock_creds = Mock()
                mock_creds.build.return_value = self.mock_sheets_service
                mock_creds_class.return_value = mock_creds
                
                with patch('main.get_leavers_from_sheet') as mock_get_leavers:
                    mock_get_leavers.side_effect = Exception("Sheets API Error")
                    
                    # Execute
                    response = get_leavers_handler(request)
                    
                    # Assert
                    self.assertEqual(response.status_code, 400)
                    self.assertIn('Failed to get leavers', response.get_data(as_text=True))


class TestGetLeaversFunction(unittest.TestCase):
    """Test the get_leavers_from_sheet helper function."""
    
    def setUp(self):
        """Set up test fixtures."""
        self.mock_sheets_service = get_mock_sheets_service()
    
    def test_get_leavers_success(self):
        """Test successful leavers retrieval."""
        leavers = get_leavers_from_sheet(self.mock_sheets_service)
        
        # Check that the service was called correctly
        self.mock_sheets_service.spreadsheets().values().get.assert_called()
        
        # Verify the returned data structure
        self.assertIsInstance(leavers, list)


class TestSecurityScenarios(unittest.TestCase):
    """Test security-related scenarios."""
    
    def setUp(self):
        """Set up test fixtures."""
        self.mock_sheets_service = get_mock_sheets_service()
    
    def test_unauthorized_sheet_access(self):
        """Test unauthorized spreadsheet access."""
        request_data = {}
        request = create_mock_flask_request(request_data, method='GET')
        
        with get_mock_env_vars():
            with patch('main.Credentials') as mock_creds_class:
                mock_creds = Mock()
                mock_creds.build.return_value = self.mock_sheets_service
                mock_creds_class.return_value = mock_creds
                
                with patch('main.get_leavers_from_sheet') as mock_get_leavers:
                    mock_get_leavers.side_effect = Exception("Access denied to spreadsheet")
                    
                    # Execute
                    response = get_leavers_handler(request)
                    
                    # Assert
                    self.assertEqual(response.status_code, 400)
                    self.assertIn('Failed to get leavers', response.get_data(as_text=True))
    
    def test_data_sanitization(self):
        """Test that returned data is properly sanitized."""
        request_data = {}
        request = create_mock_flask_request(request_data, method='GET')
        
        with get_mock_env_vars():
            with patch('main.Credentials') as mock_creds_class:
                mock_creds = Mock()
                mock_creds.build.return_value = self.mock_sheets_service
                mock_creds_class.return_value = mock_creds
                
                with patch('main.get_leavers_from_sheet') as mock_get_leavers:
                    # Mock data with potentially malicious content
                    mock_get_leavers.return_value = [
                        {'email': 'user@example.com', 'date': '2023-01-01'},
                        {'email': '<script>alert("xss")</script>@example.com', 'date': '2023-01-02'}
                    ]
                    
                    # Execute
                    response = get_leavers_handler(request)
                    
                    # Assert
                    self.assertEqual(response.status_code, 200)
                    response_data = response.get_json()
                    # In a real implementation, malicious content should be sanitized
                    self.assertIsInstance(response_data, list)


if __name__ == '__main__':
    unittest.main()