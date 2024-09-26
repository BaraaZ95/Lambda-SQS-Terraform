import json
import logging
import os
import time
import traceback
from enum import Enum
from typing import Any, Dict

import boto3
from botocore.exceptions import ClientError
from custom_exceptions import InvalidHeaderError, InvalidPathError

# Constants
SQS_QUEUE_URL = os.environ.get("SQS_QUEUE_URL")
DEFAULT_LOG_LEVEL = "INFO"


# Enums
class EnvType(Enum):
    SQS = "sqs"
    SYNC = "sync"


class MessageType(Enum):
    USER_PROFILE = "user_profile"


# Setup
sqs = boto3.client("sqs", region_name="us-east-1")
logger = logging.getLogger()


def setup_logging() -> None:
    log_level_str = os.getenv("LOGGING_LEVEL", DEFAULT_LOG_LEVEL)
    log_level = getattr(logging, log_level_str.upper(), logging.INFO)
    logging.basicConfig(
        format="%(asctime)s : %(levelname)s : %(message)s", level=log_level, force=True
    )


def validate_type_header(headers: Dict[str, str]) -> EnvType:
    type_header = headers.get("type")
    try:
        return EnvType(type_header)
    except ValueError:
        raise InvalidHeaderError("Invalid type header. Must be 'sqs' or 'sync'.")


def send_sqs_message(message: Dict[str, Any]) -> None:
    try:
        sqs.send_message(QueueUrl=SQS_QUEUE_URL, MessageBody=json.dumps(message))
    except ClientError as e:
        logger.error(f"Failed to send SQS message: {e}")
        raise


def handle_sync_request(event_path: Dict[str, str]) -> Dict[str, Any]:
    if "user_id" in event_path:
        user_id = event_path.get("user_id")
        if not user_id:
            raise InvalidPathError("Invalid user_id. Please enter valid user_id.")
        logger.info(f"User profile data processing queued for user_id: {user_id}")
        return {
            "statusCode": 200,
            "body": {
                "message": f"Not sending to SQS, handling response synchronously. User profile data processing queued for user_id: {user_id}"
            },
        }
    else:
        raise InvalidPathError("Invalid url path. Please enter a valid path.")


def handle_sqs_request(event_path: Dict[str, str]) -> Dict[str, Any]:
    if "user_id" in event_path:
        user_id = event_path.get("user_id")
        if not user_id:
            raise InvalidPathError("Invalid user_id. Please enter valid user_id.")
        message = {"type": MessageType.USER_PROFILE.value, "user_id": user_id}
        send_sqs_message(message)
        logger.info(f"User profile data processing queued for user_id: {user_id}")
        return {
            "statusCode": 202,
            "body": {
                "message": f"Response sent to SQS. User profile data processing queued for user_id: {user_id}"
            },
        }
    else:
        raise InvalidPathError("Invalid url path. Please enter a valid path.")


def handler(event: Dict[str, Any], context: Any) -> Dict[str, Any]:
    setup_logging()
    logger.info("Lambda Function Started.")
    try:
        headers = event.get("headers", {})
        event_path = event.get("pathParameters", {})
        env_type = validate_type_header(headers)

        if env_type == EnvType.SYNC:
            response = handle_sync_request(event_path)
        elif env_type == EnvType.SQS:
            response = handle_sqs_request(event_path)
            # print(response)
        else:
            raise InvalidHeaderError("Invalid environment type")

        logger.info("Lambda Function Finished Successfully.")
        return {
            "statusCode": response["statusCode"],
            "headers": {"Content-Type": "application/json"},
            "body": json.dumps(response["body"], ensure_ascii=False),
            "isBase64Encoded": False,
        }
    except (InvalidHeaderError, InvalidPathError, ValueError) as e:
        logger.error(f"Client error: {str(e)}")
        return {
            "statusCode": 400,
            "headers": {"Content-Type": "application/json"},
            "body": json.dumps({"message": str(e)}),
        }
    except Exception as e:
        logger.error(f"Unexpected error: {str(e)}")
        logger.error(traceback.format_exc())
        return {
            "statusCode": 500,
            "headers": {"Content-Type": "application/json"},
            "body": json.dumps({"message": "An unexpected error occurred"}),
        }


def process_queue(event: Dict[str, Any], context: Any) -> None:
    setup_logging()
    logger.info("SQS invoked")
    for record in event["Records"]:
        message = json.loads(record["body"])
        try:
            if message["type"] == MessageType.USER_PROFILE.value:
                user_id = message["user_id"]
                logger.info(f"Simulating SQS processing profile for user_id: {user_id}")
                time.sleep(3)
                logger.info(f"Updated user with id {user_id} profile in database.")
            else:
                logger.error(f"Unknown message type: {message['type']}")
        except Exception as e:
            logger.error(f"Error processing message: {str(e)}")
            logger.error(traceback.format_exc())
