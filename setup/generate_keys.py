
from pathlib import Path

from cryptography.hazmat.primitives import serialization
from cryptography.hazmat.primitives.asymmetric import rsa

SECRETS_DIR = Path(__file__).resolve().parent.parent / ".secrets"
PRIVATE_KEY = SECRETS_DIR / "snowflake_key.p8"
PUBLIC_KEY = SECRETS_DIR / "snowflake_key.pub"


def main():
    if PRIVATE_KEY.exists():
        raise SystemExit(f"{PRIVATE_KEY} already exists. Delete it first only if you want to rotate the key.")
    SECRETS_DIR.mkdir(exist_ok=True)

    key = rsa.generate_private_key(public_exponent=65537, key_size=2048)
    PRIVATE_KEY.write_bytes(key.private_bytes(
        encoding=serialization.Encoding.PEM,
        format=serialization.PrivateFormat.PKCS8,
        encryption_algorithm=serialization.NoEncryption(),
    ))
    public_pem = key.public_key().public_bytes(
        encoding=serialization.Encoding.PEM,
        format=serialization.PublicFormat.SubjectPublicKeyInfo,
    )
    PUBLIC_KEY.write_bytes(public_pem)

    body = "".join(public_pem.decode().splitlines()[1:-1])  # without the BEGIN/END lines
    print(f"Private key: {PRIVATE_KEY}")
    print(f"Public key:  {PUBLIC_KEY}")
    print("\nPaste this value as RSA_PUBLIC_KEY in setup/snowflake_setup.sql:\n")
    print(body)


if __name__ == "__main__":
    main()
