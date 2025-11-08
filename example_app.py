"""
Example Python application for CodeQL security analysis demonstration.

This module demonstrates common patterns and potential security considerations
that CodeQL can analyze.
"""

import os
import subprocess
import hashlib
from typing import Optional


class UserManager:
    """Example user management class with security considerations."""

    def __init__(self, database_path: str):
        """Initialize user manager with database path."""
        self.database_path = database_path
        self.users = {}

    def hash_password(self, password: str) -> str:
        """
        Hash a password using SHA-256.

        Note: In production, use bcrypt, scrypt, or argon2 instead.
        """
        return hashlib.sha256(password.encode()).hexdigest()

    def create_user(self, username: str, password: str) -> bool:
        """
        Create a new user with hashed password.

        Args:
            username: The username to create
            password: The user's password (will be hashed)

        Returns:
            True if user was created successfully
        """
        if username in self.users:
            return False

        hashed_password = self.hash_password(password)
        self.users[username] = {
            'password': hashed_password,
            'created_at': os.getenv('TIMESTAMP', 'unknown')
        }
        return True

    def verify_user(self, username: str, password: str) -> bool:
        """
        Verify user credentials.

        Args:
            username: The username to verify
            password: The password to check

        Returns:
            True if credentials are valid
        """
        if username not in self.users:
            return False

        hashed_password = self.hash_password(password)
        return self.users[username]['password'] == hashed_password


class FileManager:
    """Example file management with path handling."""

    @staticmethod
    def read_file(filepath: str) -> Optional[str]:
        """
        Read a file safely with proper error handling.

        Args:
            filepath: Path to the file to read

        Returns:
            File contents or None if error occurs
        """
        try:
            # Validate path to prevent directory traversal
            if '..' in filepath:
                raise ValueError("Invalid file path")

            with open(filepath, 'r', encoding='utf-8') as f:
                return f.read()
        except (IOError, ValueError) as e:
            print(f"Error reading file: {e}")
            return None

    @staticmethod
    def write_file(filepath: str, content: str) -> bool:
        """
        Write content to a file safely.

        Args:
            filepath: Path to write to
            content: Content to write

        Returns:
            True if successful
        """
        try:
            # Validate path
            if '..' in filepath:
                raise ValueError("Invalid file path")

            with open(filepath, 'w', encoding='utf-8') as f:
                f.write(content)
            return True
        except (IOError, ValueError) as e:
            print(f"Error writing file: {e}")
            return False


class SystemUtils:
    """System utility functions with security considerations."""

    @staticmethod
    def run_command(command: list) -> Optional[str]:
        """
        Run a system command safely.

        Args:
            command: Command as list of arguments

        Returns:
            Command output or None if error
        """
        try:
            # Use list form to prevent shell injection
            result = subprocess.run(
                command,
                capture_output=True,
                text=True,
                check=True,
                timeout=10
            )
            return result.stdout
        except (subprocess.CalledProcessError, subprocess.TimeoutExpired) as e:
            print(f"Error running command: {e}")
            return None

    @staticmethod
    def get_env_variable(name: str, default: str = "") -> str:
        """
        Get environment variable safely.

        Args:
            name: Environment variable name
            default: Default value if not found

        Returns:
            Environment variable value or default
        """
        return os.getenv(name, default)


def main():
    """Main function demonstrating usage."""
    # Example usage
    user_manager = UserManager("/var/data/users.db")

    # Create a user
    if user_manager.create_user("admin", "secure_password_123"):
        print("User created successfully")

    # Verify credentials
    if user_manager.verify_user("admin", "secure_password_123"):
        print("Authentication successful")

    # File operations
    file_manager = FileManager()
    content = file_manager.read_file("example.txt")
    if content:
        print(f"File content: {content[:100]}")

    # System utilities
    utils = SystemUtils()
    hostname = utils.run_command(["hostname"])
    if hostname:
        print(f"Hostname: {hostname.strip()}")


if __name__ == "__main__":
    main()
