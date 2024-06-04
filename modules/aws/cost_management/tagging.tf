# Setup Cost Allocation Tags for reporting
resource "aws_ce_cost_allocation_tag" "default" {
  count   = length(var.cost_allocation_tags)
  tag_key = var.cost_allocation_tags[count.index]
  status  = "Active"
}