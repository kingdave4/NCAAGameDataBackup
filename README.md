# NCAA Game Data Backup

**Project #6: SportsDataBackup**

Welcome to **SportsDataBackup**—an evolution of our previous NCAA Game Highlights project. This upgrade enhances reliability and efficiency by integrating AWS DynamoDB for query backups and AWS EventBridge for daily automated triggers using ECS Fargate. With Terraform provisioning our AWS infrastructure and Docker handling containerization, your NCAA game highlights are fetched, processed, and delivered seamlessly while MediaConvert ensures top-notch video quality.

---

## Project Overview

This project demonstrates how to:

- **Fetch Game Data**: Query the Sports Highlights API (via RapidAPI) to retrieve the latest NCAA game highlights.
- **Backup & Store Data**: Use AWS DynamoDB to securely back up query data and AWS S3 to store video metadata.
- **Event-Driven Automation**: Leverage AWS EventBridge to schedule daily triggers, automating the entire workflow.
- **Video Processing**: Process the initial video via AWS MediaConvert to ensure optimal quality.
- **Containerization & IaC**: Run the complete pipeline within a Docker container while provisioning AWS resources using Terraform.

---

## Key Features

- **RapidAPI Integration**: Access NCAA game highlights via a free-tier API endpoint.
- **AWS-Powered Workflow**:
  - **DynamoDB**: Backup and store query data for high reliability.
  - **S3 & MediaConvert**: Manage metadata storage and process videos for quality output.
  - **ECS Fargate**: Run containerized tasks without managing servers.
  - **EventBridge**: Automate daily triggers to keep your data up-to-date.
- **Dockerized Pipeline**: Ensure consistent deployment environments.
- **Terraform Automation**: Provision and manage AWS resources with Infrastructure as Code.
- **Secure Configuration**: Use environment variables and AWS Secrets Manager to protect sensitive credentials.

---

## Technical Diagram

![image](https://github.com/user-attachments/assets/0cc7fe62-213b-4d80-8f52-792721267c98)

---

## File Structure

```plaintext
NCAAGameDataBackup/
├── src/
│   ├── Dockerfile                # Instructions to build the Docker image
│   ├── config.py                 # Loads environment variables with sensible defaults
│   ├── fetch.py                  # Fetches NCAA highlights from RapidAPI and stores metadata in S3
│   ├── mediaconvert_process.py   # Submits a job to AWS MediaConvert for video processing
│   ├── process_one_video.py      # Processes the first video from S3 metadata and re-uploads it
│   ├── run_all.py                # Orchestrates the execution of all scripts
│   ├── requirements.txt          # Python dependencies for the project
│   ├── .env                      # Environment variables (API keys, AWS credentials, etc.)
│   └── .gitignore                # Files to exclude from Git
├── terraform/
│   ├── main.tf                   # Main Terraform configuration file
│   ├── variables.tf              # Variable definitions
│   ├── secrets.tf                # AWS Secrets Manager and sensitive data provisioning
│   ├── dynamodb.tf               # DynamoDB table configuration
│   ├── eventbridge.tf            # EventBridge rules and configuration
│   ├── iam.tf                    # IAM roles and policies
│   ├── ecr.tf                    # ECR repository configuration
│   ├── ecs.tf                    # ECS cluster and service configuration
│   ├── s3.tf                     # S3 bucket provisioning for video storage
│   ├── container_definitions.tpl # Template for container definitions
│   ├── terraform.tfvars          # Variables for the Terraform configuration
│   └── outputs.tf                # Terraform outputs
└── README.md                     # Project documentation
```

## Prerequisites

Before you dive in, make sure you have:
- RapidAPI Account: Sign up at RapidAPI and subscribe to the Sports Highlights API (using NCAA highlights for free).
- Docker: Verify installation with docker --version
- AWS CLI: Ensure AWS CLI is installed and configured (aws --version)
- Python 3: Check your Python version with python3 --version
- AWS Account Details: Your AWS Account ID and valid IAM access keys.

Environment Configuration
### 1. Create the .env File for Local Runs
In the root of your project (or within the src directory), create a file named .env and paste the following content. Update the placeholder values with your actual credentials and configuration details. This file will be used when running the project locally.

``` env
# .env

API_URL=https://sport-highlights-api.p.rapidapi.com/basketball/highlights
RAPIDAPI_HOST=sport-highlights-api.p.rapidapi.com
RAPIDAPI_KEY=your_rapidapi_key_here
AWS_ACCESS_KEY_ID=your_aws_access_key_id_here
AWS_SECRET_ACCESS_KEY=your_aws_secret_access_key_here
AWS_DEFAULT_REGION=us-east-1
S3_BUCKET_NAME=your_S3_bucket_name_here
AWS_REGION=us-east-1
DATE=2023-12-01
LEAGUE_NAME=NCAA
LIMIT=5
MEDIACONVERT_ENDPOINT=https://your_mediaconvert_endpoint_here.amazonaws.com
MEDIACONVERT_ROLE_ARN=arn:aws:iam::your_account_id:role/YourMediaConvertRole
INPUT_KEY=highlights/basketball_highlights.json
OUTPUT_KEY=videos/first_video.mp4
RETRY_COUNT=3
RETRY_DELAY=30
WAIT_TIME_BETWEEN_SCRIPTS=60
DYNAMODB_TABLE=your_dynamodb_table_name_here
```

### 2. Create the terraform.tfvars File for Deploying Terraform Code

Inside the terraform/ directory, create a file named terraform.tfvars with the following content (update placeholders as needed):

``` tf
# terraform.tfvars

aws_region                = "us-east-1" # your preferred region here
project_name              = "your_project_name_here"  # Enter your own project name here
s3_bucket_name            = "your_S3_bucket_name_here"
ecr_repository_name       = "your_ecr_repository_name_here"

rapidapi_ssm_parameter_arn = "arn:aws:ssm:us-east-1:xxxxxxxxxxxx:parameter/myproject/rapidapi_key"

mediaconvert_endpoint     = "https://your_mediaconvert_endpoint_here.amazonaws.com"
mediaconvert_role_arn     = "" 
# Optionally, specify your custom MediaConvert role ARN here. For example:
# mediaconvert_role_arn = "arn:aws:iam::123456789012:role/YourCustomMediaConvertRole"
# Leaving this string empty will use the role that is automatically created by the Terraform scripts.

retry_count               = 3
retry_delay               = 60
```
Make sure to replace placeholder values with your actual configuration details.


### Setup & Deployment

### 1. Clone the Repository
```bash
git clone https://github.com/kingdave4/NCAAGameDataBackup.git
cd NCAAGameDataBackup
```

### 2. Add Your API Key to AWS Secrets Manager
Store your RapidAPI key securely:
```bash
aws secretsmanager create-secret \
    --name my-api-key \
    --description "API key for accessing the Sports Highlights API" \
    --secret-string '{"api_key":"YOUR_ACTUAL_API_KEY"}' \
    --region us-east-1
```

### 3. Update the .env File
Ensure that your .env file (created earlier) contains all necessary configuration values and is secured:
``` bash
chmod 600 .env
```

## Build & Run Locally with Docker
Build the Docker image:
``` bash
docker build -t highlight-processor .
```
Run the container:
``` bash
docker run --env-file .env highlight-processor
```

The container executes the pipeline: fetching highlights, processing a video, and submitting a MediaConvert job. Verify the output files in your S3 bucket:
- JSON metadata file
- Raw video in videos/
- Processed video in processed_videos/

## Terraform & Deployment to AWS
Provision AWS Resources with Terraform

### 1. Navigate to the Terraform directory:
``` bash
cd terraform
```

### 2. Initialize the Terraform workspace:
``` bash
terraform init
```

### 3. Validate the configuration:
``` bash
terraform validate
```

### 4. Preview the execution plan:
``` bash
terraform plan
```
### 5. Apply the configuration (using your variable file):
``` bash
terraform apply -var-file="terraform.tfvars"
```

## Deploy Docker Image to AWS ECR
### 1. Log in to AWS ECR:

``` bash
aws ecr get-login-password --region us-east-1 | \
  docker login --username AWS --password-stdin <AWS_ACCOUNT_ID>.dkr.ecr.us-east-1.amazonaws.com
```
### 2. Build, tag, and push the Docker image:

``` bash
docker build -t highlight-pipeline:latest .
docker tag highlight-pipeline:latest <AWS_ACCOUNT_ID>.dkr.ecr.<REGION>.amazonaws.com/highlight-pipeline:latest
docker push <AWS_ACCOUNT_ID>.dkr.ecr.<REGION>.amazonaws.com/highlight-pipeline:latest
```

### Clean up and destroy all the AWS resources that was created.
``` bash
terraform destroy -auto-approve
```

### Key takeaways from Project #5:
- Leveraging containerization (Docker) to ensure consistency.
- Integrating multiple AWS services (S3, MediaConvert, ECS) for a robust media pipeline.
- Automating infrastructure setup using Terraform.
- Emphasizing secure configuration management via environment variables and Secrets Manager.

### Future Enhancements
- Expand Terraform scripts to provision additional AWS resources.
- Increase the number of videos processed concurrently.
- Transition from static date queries to dynamic time ranges (e.g., last 30 days).
- Improve logging and error handling for enhanced observability.
