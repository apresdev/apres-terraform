# Zips the binary file
data "archive_file" "lambda" {
  type        = "zip"
  source_file = var.binary_path
  output_path = local.archive_path
}
