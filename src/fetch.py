# fetch.py

import json
import boto3
import requests
import botocore.exceptions
from config import (
    API_URL,             # API endpoint for fetching highlights
    RAPIDAPI_HOST,       # RapidAPI host
    RAPIDAPI_KEY,        # RapidAPI key for authentication
    DATE,                # Date for which to fetch highlights
    LEAGUE_NAME,         # League name (e.g., NCAA)
    LIMIT,               # Maximum number of highlights to fetch
    S3_BUCKET_NAME,      # S3 bucket name for storing data
    AWS_REGION,          # AWS region for S3 and DynamoDB
    DYNAMODB_TABLE       # DynamoDB table name for storing highlights
)

def fetch_highlights():
    """
    Fetch highlights from the API.
    Returns a JSON dictionary of highlights if successful; otherwise, None.
    """
    try:
        # Set query parameters and headers
        query_params = {"date": DATE, "leagueName": LEAGUE_NAME, "limit": LIMIT}
        headers = {"X-RapidAPI-Key": RAPIDAPI_KEY, "X-RapidAPI-Host": RAPIDAPI_HOST}

        # Make the API request with a timeout of 120 seconds
        response = requests.get(API_URL, headers=headers, params=query_params, timeout=120)
        response.raise_for_status()  # Raises an exception for HTTP errors

        highlights = response.json()
        print("Highlights fetched successfully!")
        return highlights

    except requests.exceptions.RequestException as e:
        print(f"Error fetching highlights: {e}")
        return None

def save_to_s3(data, file_name):
    """
    Save JSON data to an S3 bucket.
    Creates the bucket if it does not exist.
    
    Args:
        data (dict): The data to save.
        file_name (str): Base name for the file (without extension).
    """
    try:
        # Create an S3 client for the specified region
        s3 = boto3.client("s3", region_name=AWS_REGION)

        # Check if the bucket exists; if not, create it.
        try:
            s3.head_bucket(Bucket=S3_BUCKET_NAME)
            print(f"Bucket {S3_BUCKET_NAME} exists.")
        except Exception:
            print(f"Bucket {S3_BUCKET_NAME} does not exist. Creating it...")
            # For 'us-east-1', no LocationConstraint is needed
            if AWS_REGION == "us-east-1":
                s3.create_bucket(Bucket=S3_BUCKET_NAME)
            else:
                s3.create_bucket(
                    Bucket=S3_BUCKET_NAME,
                    CreateBucketConfiguration={"LocationConstraint": AWS_REGION}
                )
            print(f"Bucket {S3_BUCKET_NAME} created successfully.")

        # Define the S3 object key and upload the JSON data
        s3_key = f"highlights/{file_name}.json"
        s3.put_object(
            Bucket=S3_BUCKET_NAME,
            Key=s3_key,
            Body=json.dumps(data),
            ContentType="application/json"
        )
        print(f"Highlights saved to S3: s3://{S3_BUCKET_NAME}/{s3_key}")

    except Exception as e:
        print(f"Error saving to S3: {e}")

def ensure_dynamodb_table(dynamodb, table_name):
    """
    Check if a DynamoDB table exists; if not, create it.
    
    Args:
        dynamodb: The boto3 DynamoDB resource.
        table_name (str): The name of the DynamoDB table.
    
    Returns:
        The DynamoDB Table resource.
    """
    table = dynamodb.Table(table_name)
    try:
        # Try loading table metadata to confirm its existence
        table.load()
        print(f"DynamoDB table '{table_name}' exists.")
    except botocore.exceptions.ClientError as e:
        error_code = e.response['Error']['Code']
        if error_code == 'ResourceNotFoundException':
            print(f"DynamoDB table '{table_name}' not found. Creating table...")
            # Create the table with 'id' as the primary key (string type)
            table = dynamodb.create_table(
                TableName=table_name,
                KeySchema=[{'AttributeName': 'id', 'KeyType': 'HASH'}],
                AttributeDefinitions=[{'AttributeName': 'id', 'AttributeType': 'S'}],
                BillingMode='PAY_PER_REQUEST'
            )
            # Wait until the table exists before proceeding
            table.wait_until_exists()
            print(f"DynamoDB table '{table_name}' created successfully.")
        else:
            print(f"Unexpected error checking table: {e}")
            raise e
    return table

def store_highlights_to_dynamodb(highlights):
    """
    Store each highlight record into a DynamoDB table.
    
    Assumes 'highlights' contains a key "data" with a list of records.
    """
    try:
        # Initialize the DynamoDB resource and ensure the table exists.
        dynamodb = boto3.resource("dynamodb", region_name=AWS_REGION)
        table = ensure_dynamodb_table(dynamodb, DYNAMODB_TABLE)
        
        # Loop through each record in the fetched highlights
        for record in highlights.get("data", []):
            # Use the 'id' field or fall back to the 'url' field as a unique key
            item_key = record.get("id") or record.get("url")
            if not item_key:
                continue  # Skip record if no unique identifier exists

            item_key = str(item_key)  # Ensure the key is a string
            record["id"] = item_key     # Set the record's id
            record["fetch_date"] = DATE # Optionally store the fetch date

            # Save the record into DynamoDB
            table.put_item(Item=record)
            print(f"Stored record with key {item_key} into DynamoDB.")

    except Exception as e:
        print(f"Error storing highlights in DynamoDB: {e}")

def process_highlights():
    """
    Main function: Fetch highlights, save them to S3, and store them in DynamoDB.
    """
    print("Fetching highlights...")
    highlights = fetch_highlights()
    if highlights:
        print("Saving highlights to S3...")
        save_to_s3(highlights, "basketball_highlights")
        print("Storing highlights in DynamoDB...")
        store_highlights_to_dynamodb(highlights)
    else:
        print("No highlights fetched.")

if __name__ == "__main__":
    process_highlights()
