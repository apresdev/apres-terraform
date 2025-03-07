# Zips the binary file
data "archive_file" "lambda" {
  count       = var.source_file == "" ? 0 : 1
  type        = "zip"
  source_file = var.source_file
  output_path = local.archive_path
}
