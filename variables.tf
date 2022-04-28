# Input variable definitions

variable "aws_region" {
  description = "AWS region for all resources."

  type    = string
  default = "us-east-1"
}
variable "lambda_service_role_name" {
  description = "Service role name for the lambda function"
  type        = string
  default     = "AWSLambdaBasicExecutionRole"

}
variable "dynamo_db_table" {
  description = "Service role name for the lambda function"
  type        = string


}
