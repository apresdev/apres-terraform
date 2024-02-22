
resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = var.nat_instance_dashboard_name
  dashboard_body = jsonencode({
    "widgets" : [
      {
        "height" : 15,
        "width" : 24,
        "y" : 0,
        "x" : 0,
        "type" : "explorer",
        "properties" : {
          "metrics" : [
            {
              "metricName" : "CPUUtilization",
              "resourceType" : "AWS::EC2::Instance",
              "stat" : "Average"
            },
            {
              "metricName" : "CPUCreditBalance",
              "resourceType" : "AWS::EC2::Instance",
              "stat" : "Average"
            },
            {
              "metricName" : "NetworkPacketsIn",
              "resourceType" : "AWS::EC2::Instance",
              "stat" : "Average"
            },
            {
              "metricName" : "NetworkPacketsOut",
              "resourceType" : "AWS::EC2::Instance",
              "stat" : "Average"
            },
            {
              "metricName" : "NetworkIn",
              "resourceType" : "AWS::EC2::Instance",
              "stat" : "Average"
            },
            {
              "metricName" : "NetworkOut",
              "resourceType" : "AWS::EC2::Instance",
              "stat" : "Average"
            }
          ],
          "aggregateBy" : {
            "key" : "",
            "func" : ""
          },
          "labels" : [
            {
              "key" : "application",
              "value" : "VPC"
            }
          ],
          "widgetOptions" : {
            "legend" : {
              "position" : "bottom"
            },
            "view" : "timeSeries",
            "stacked" : false,
            "rowsPerPage" : 50,
            "widgetsPerRow" : 2
          },
          "period" : 60,
          "splitBy" : "",
          "region" : "us-east-2",
          "title" : ""
        }
      }
    ]
  })
}