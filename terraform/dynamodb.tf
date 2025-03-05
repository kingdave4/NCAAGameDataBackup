resource "aws_dynamodb_table" "sports_highlights" {
  name         = var.DYNAMODB_TABLE
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "id"

  attribute {
    name = "id"
    type = "S"
  }
}

