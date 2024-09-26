import json
import os
import sys
import unittest
from unittest.mock import patch

# Add the lambda directory to the Python path
sys.path.append(
    os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "lambda"))
)

from custom_exceptions import InvalidHeaderError, InvalidPathError
from lambda_function import EnvType, MessageType, handler, process_queue


class TestLambdaFunctions(unittest.TestCase):
    @patch("lambda_function.validate_type_header")
    @patch("lambda_function.handle_sync_request")
    @patch("lambda_function.handle_sqs_request")
    def test_handler_sync(self, mock_sqs, mock_sync, mock_validate):
        mock_validate.return_value = EnvType.SYNC
        mock_sync.return_value = {
            "statusCode": 200,
            "body": {"message": "Sync processed"},
        }

        event = {"headers": {"type": "sync"}, "pathParameters": {"user_id": "123"}}
        context = {}

        result = handler(event, context)

        self.assertEqual(result["statusCode"], 200)
        self.assertIn("Sync processed", json.loads(result["body"])["message"])

    @patch("lambda_function.validate_type_header")
    @patch("lambda_function.handle_sync_request")
    @patch("lambda_function.handle_sqs_request")
    def test_handler_sqs(self, mock_sqs, mock_sync, mock_validate):
        mock_validate.return_value = EnvType.SQS
        mock_sqs.return_value = {"statusCode": 202, "body": {"message": "SQS queued"}}

        event = {"headers": {"type": "sqs"}, "pathParameters": {"user_id": "123"}}
        context = {}

        result = handler(event, context)

        self.assertEqual(result["statusCode"], 202)
        self.assertIn("SQS queued", json.loads(result["body"])["message"])

    @patch("lambda_function.time.sleep")  # Mock sleep to speed up tests
    @patch("lambda_function.logger")
    def test_process_queue(self, mock_logger, mock_sleep):
        event = {
            "Records": [
                {
                    "body": json.dumps(
                        {"type": MessageType.USER_PROFILE.value, "user_id": "123"}
                    )
                }
            ]
        }
        context = {}

        process_queue(event, context)

        mock_logger.info.assert_any_call("SQS invoked")
        mock_logger.info.assert_any_call(
            "Simulating SQS processing profile for user_id: 123"
        )
        mock_logger.info.assert_any_call(
            "Updated user with id 123 profile in database."
        )

    @patch("lambda_function.validate_type_header")
    def test_handler_invalid_header(self, mock_validate):
        mock_validate.side_effect = InvalidHeaderError("Invalid type header")

        event = {"headers": {"type": "invalid"}, "pathParameters": {"user_id": "123"}}
        context = {}

        result = handler(event, context)

        self.assertEqual(result["statusCode"], 400)
        self.assertIn("Invalid type header", json.loads(result["body"])["message"])

    @patch("lambda_function.validate_type_header")
    @patch("lambda_function.handle_sync_request")
    def test_handler_invalid_path(self, mock_sync, mock_validate):
        mock_validate.return_value = EnvType.SYNC
        mock_sync.side_effect = InvalidPathError("Invalid url path")

        event = {"headers": {"type": "sync"}, "pathParameters": {}}
        context = {}

        result = handler(event, context)

        self.assertEqual(result["statusCode"], 400)
        self.assertIn("Invalid url path", json.loads(result["body"])["message"])


if __name__ == "__main__":
    unittest.main()
