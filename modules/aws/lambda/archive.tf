# Zips the binary file
data "archive_file" "lambda" {
  count       = var.skip_zip ? 0 : 1
  type        = "zip"
  source_file = var.binary_path
  output_path = local.archive_path
}
