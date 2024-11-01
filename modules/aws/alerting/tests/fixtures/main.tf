locals {
  slack_channels = {
    "us-east-2" : "C07UFAHAA2H" # aws-sandbox-us-east-2
    "us-west-2" : "C07UBHJ47HC" # aws-sandbox-us-west-2
  }
  teams_channels = {
    "us-east-2" : "19%3Ad1ecad0ba1c94c0abe400c93ad533123%40thread.tacv2" # aws-sandbox-us-east-2
    "us-west-2" : "19%3A4c64f77fdeb84f298d610f7030b1e13e%40thread.tacv2" # aws-sandbox-us-west-2
  }
}
module "alerts" {
  source             = "../../"
  name               = "UnitTest"
  environment        = "UnitTest"
  application        = "UnitTest"
  component          = "UnitTest"
  owner              = "Engineering"
  slack_workspace_id = "T06EZMX3THV"                          # Apres
  msteams_team_id    = "048113e8-d452-4921-95dd-be5f410e7aaf" # Apres
  msteams_tenant_id  = "35591627-bdde-4d16-a221-bf72ffc20990"
  # This is an untypical setup in that we're creating both slack & teams alerts.
  chatbot_slack_config = [
    {
      name                = "SlackTest"
      publishing_services = ["cloudwatch.amazonaws.com"]
      slack_channel_id    = local.slack_channels[data.aws_region.current.name]
    }
  ]
  chatbot_msteams_config = [
    {
      name                = "TeamsTest"
      publishing_services = ["cloudwatch.amazonaws.com"]
      msteams_channel_id  = local.teams_channels[data.aws_region.current.name]
    }
  ]
}