module "api_gateway" {
  source                   = "../"
  lambda_service_role_name = "dynamoDB_access"
  dynamo_db_table          = "testing-table"
}
