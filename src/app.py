import logging
import os
from base64 import b64decode
import boto3

logger = logging.getLogger()
logger.setLevel(logging.INFO)

def lambda_handler(event, context):
    logger.info(f"event: {event}")
    logger.info(f"context: {context}")

    encrypted_api_key_value = os.environ["api_key"]
    logger.info(f"Encrypted key: {encrypted_api_key_value}")

    decrypted_api_key_value = boto3.client('kms').decrypt(
        CiphertextBlob=b64decode(encrypted_api_key_value)
        )['Plaintext'].decode('utf-8')
    logger.info(f"Decrypted key: {decrypted_api_key_value}")

    return event
