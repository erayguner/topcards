import os
def main():
    print("This is a test script in the .github directory.")
    print("Current working directory:", os.getcwd())
    print("Environment variable TEST_VAR:", os.getenv('TEST_VAR', 'Not set'))
if __name__ == "__main__":
    main()
    