resource "aws_dynamodb_table" "basic-dynamodb-table" {
  name           = var.dynamo_db_table
  billing_mode   = "PROVISIONED"
  read_capacity  = 10
  write_capacity = 10
  hash_key       = "id"
  attribute {
    name = "id"
    type = "S"
  }
}
