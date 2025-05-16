import json
import argparse
import getpass
from eth_account import Account

def main():
    # Setup argument parser
    parser = argparse.ArgumentParser(description="Decrypt Ethereum keystore file.")
    parser.add_argument("keyfile", help="Path to the Ethereum keystore file")
    args = parser.parse_args()

    # Prompt for password
    password = getpass.getpass(prompt="Enter keystore password: ")

    # Load the keystore JSON
    try:
        with open(args.keyfile, 'r') as file:
            keystore = json.load(file)
    except FileNotFoundError:
        print("Keystore file not found.")
        return
    except json.JSONDecodeError:
        print("Invalid JSON in keystore file.")
        return

    # Attempt to decrypt
    try:
        private_key = Account.decrypt(keystore, password)
        print(f"Public Key:  0x{keystore.get('address')}")
        print(f"Private Key: 0x{private_key.hex()}")
    except ValueError as e:
        print("Failed to decrypt keystore. Check your password.")
        print(e)

if __name__ == "__main__":
    main()
