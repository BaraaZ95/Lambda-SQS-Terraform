# Serverless AWS Lambda Project with Terraform

## Overview

This project implements a scalable, serverless architecture using AWS Lambda, SQS, and API Gateway. It's designed to handle both synchronous and asynchronous processing of user profile data, providing a responsive user experience even for long-running tasks.

## Architecture

- **AWS Lambda**: Two functions handle user requests and process queued tasks.
- **Amazon SQS**: Manages task queues for asynchronous processing.
- **API Gateway**: Provides RESTful API endpoints.
- **S3**: Stores Lambda layers.
- **Terraform**: Manages infrastructure as code.
- **GitHub Actions**: Automates CI/CD pipeline.

## Features

- Immediate response for user requests
- Asynchronous processing for time-consuming tasks
- Scalable and cost-effective serverless architecture
- Infrastructure as Code with Terraform
- Automated deployments with GitHub Actions

## Prerequisites

- AWS Account
- Terraform installed (version >= 1.0.0)
- AWS CLI configured with appropriate credentials
- GitHub account (for CI/CD)

## Setup

1. Clone the repository:
   ```
   git clone https://github.com/your-username/your-repo-name.git
   cd your-repo-name
   ```

2. Initialize Terraform:
   ```
   terraform init
   ```

3. Set up AWS credentials:
   - Option 1: AWS CLI
     ```
     aws configure
     ```
   - Option 2: Environment variables
     ```
     export AWS_ACCESS_KEY_ID="your_access_key"
     export AWS_SECRET_ACCESS_KEY="your_secret_key"
     export AWS_REGION="your_region"
     ```

4. Update `variables.tf` with your specific variables.

5. Deploy the infrastructure and activate the CI/CD by pushing to github:
   ```
   git push origin main
   ```

## Usage

### API Endpoints

- POST `/user/{user_id}`
  - Headers:
    - `type`: Either `"sqs"` for asynchronous or `"sync"` for synchronous processing

### Example Request

```bash
curl -X POST https://your-api-gateway-url/user/123 \
     -H "Content-Type: application/json" \
     -H "type: sqs" \
     -d '{"someData": "value"}'
```

## Development

### Lambda Functions

The main logic is in `lambda/lambda_function.py`. It contains:
- `handler`: Main entry point for API requests
- `process_queue`: Processes SQS messages

### Adding Dependencies

1. Add new dependencies to `lambda/requirements.txt`
2. Update the Lambda layer:
   ```
   ./build_layer.sh
   ```

## CI/CD

The project uses GitHub Actions for CI/CD. The workflow is defined in `.github/workflows/main.yml`.

Whenever code is pushed to the `main` branch:
1. Code is linted and formatted
2. Tests are run
3. Lambda layer is built
4. Terraform changes are planned and applied

## Monitoring and Logging

- CloudWatch Logs are set up for both Lambda functions and the SQS queue.
- Use the AWS Console or AWS CLI to access logs and metrics.

## License

This project is licensed under the MIT License - see the [LICENSE.md](LICENSE.md) file for details.

## Acknowledgments

- AWS Documentation
- Terraform Documentation
