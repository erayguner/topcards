"""Simple test to verify import functionality."""

import unittest
import sys
import os

# Test importing one function at a time
class TestSimpleImport(unittest.TestCase):
    """Test basic import functionality."""
    
    def test_create_user_import(self):
        """Test importing create_user function."""
        sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', 'functions', 'create_user'))
        try:
            import main
            self.assertTrue(hasattr(main, 'create_user_handler'))
        except ImportError as e:
            self.fail(f"Failed to import create_user main: {e}")
    
    def test_add_to_group_import(self):
        """Test importing add_to_group function."""
        sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', 'functions', 'add_to_group'))
        try:
            import main
            self.assertTrue(hasattr(main, 'add_to_group_handler'))
        except ImportError as e:
            self.fail(f"Failed to import add_to_group main: {e}")
    
    def test_conftest_import(self):
        """Test importing conftest utilities."""
        sys.path.insert(0, os.path.dirname(__file__))
        try:
            import conftest
            self.assertTrue(hasattr(conftest, 'get_mock_admin_service'))
        except ImportError as e:
            self.fail(f"Failed to import conftest: {e}")


if __name__ == '__main__':
    unittest.main()