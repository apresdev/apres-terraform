
locals {
  cw_dashboard_name = "${local.name}-ECS-Dashboard"
}
resource "aws_cloudwatch_metric_alarm" "crash_loop" {
  alarm_name          = "${local.name}-TaskCrashLoop"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 2
  metric_name         = "TaskNonZeroExitCode"
  namespace           = "Apres/ECS"
  period              = 60
  statistic           = "Sum"
  threshold           = 4
  alarm_description   = "Alarm if too many tasks exit with non-zero exit codes"
  dimensions = {
    Cluster = "${local.name}"
    Service = "${local.name}"
    Task    = "${local.name}"
  }
}


resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = local.cw_dashboard_name
  dashboard_body = jsonencode(
    {
      "widgets" : [
        {
          "height" : 6,
          "width" : 8,
          "y" : 0,
          "x" : 0,
          "type" : "metric",
          "properties" : {
            "metrics" : [
              ["ECS/ContainerInsights", "MemoryUtilized", "ServiceName", "${local.name}", "ClusterName", "${local.name}", { "region" : "${data.aws_region.current.name}", "yAxis" : "right" }],
              [".", "CpuUtilized", ".", ".", ".", ".", { "region" : "${data.aws_region.current.name}" }]
            ],
            "view" : "timeSeries",
            "stacked" : false,
            "region" : "${data.aws_region.current.name}",
            "title" : "CPU and Memory",
            "period" : 60,
            "yAxis" : {
              "left" : {
                "min" : 0,
                "max" : 100,
                "label" : "Percent",
                "showUnits" : false
              },
              "right" : {
                "min" : 0
              }
            },
            "stat" : "Average"
          }
        },
        {
          "height" : 6,
          "width" : 8,
          "y" : 0,
          "x" : 8,
          "type" : "metric",
          "properties" : {
            "metrics" : [
              ["ECS/ContainerInsights", "DesiredTaskCount", "ServiceName", "${local.name}", "ClusterName", "${local.name}", { "region" : "${data.aws_region.current.name}" }],
              [".", "TaskSetCount", ".", ".", ".", ".", { "region" : "${data.aws_region.current.name}" }],
              [".", "PendingTaskCount", ".", ".", ".", ".", { "region" : "${data.aws_region.current.name}" }],
              [".", "RunningTaskCount", ".", ".", ".", ".", { "region" : "${data.aws_region.current.name}" }]
            ],
            "view" : "timeSeries",
            "stacked" : false,
            "region" : "${data.aws_region.current.name}",
            "yAxis" : {
              "left" : {
                "min" : 0
              }
            },
            "title" : "Task Counts",
            "period" : 60,
            "stat" : "Average"
          }
        },
        {
          "height" : 6,
          "width" : 8,
          "y" : 6,
          "x" : 8,
          "type" : "metric",
          "properties" : {
            "metrics" : [
              ["ECS/ContainerInsights", "StorageWriteBytes", "ServiceName", "${local.name}", "ClusterName", "${local.name}", { "region" : "${data.aws_region.current.name}" }],
              [".", "StorageReadBytes", ".", ".", ".", ".", { "region" : "${data.aws_region.current.name}" }]
            ],
            "view" : "timeSeries",
            "stacked" : false,
            "region" : "${data.aws_region.current.name}",
            "title" : "ECS Storage I/O",
            "period" : 60,
            "stat" : "Average"
          }
        },
        {
          "height" : 6,
          "width" : 8,
          "y" : 6,
          "x" : 0,
          "type" : "metric",
          "properties" : {
            "metrics" : [
              ["ECS/ContainerInsights", "NetworkTxBytes", "ServiceName", "${local.name}", "ClusterName", "${local.name}", { "region" : "${data.aws_region.current.name}" }],
              [".", "NetworkRxBytes", ".", ".", ".", ".", { "region" : "${data.aws_region.current.name}" }]
            ],
            "view" : "timeSeries",
            "stacked" : false,
            "region" : "${data.aws_region.current.name}",
            "title" : "ECS Network IO",
            "period" : 60,
            "stat" : "Average"
          }
        },
        {
          "height" : 6,
          "width" : 8,
          "y" : 0,
          "x" : 16,
          "type" : "metric",
          "properties" : {
            "metrics" : [
              ["Apres/ECS", "TaskNonZeroExitCode", "Task", "${local.name}", "Cluster", "${local.name}", "Service", "${local.name}", { "region" : "${data.aws_region.current.name}" }]
            ],
            "view" : "timeSeries",
            "stacked" : false,
            "region" : "${data.aws_region.current.name}",
            "period" : 60,
            "stat" : "Sum",
            "title" : "Tasks with non-zero exit codes (No data is ok)",
            "yAxis" : {
              "left" : {
                "label" : "Count",
                "showUnits" : false
              }
            }
          }
        },
        {
          "type" : "metric",
          "x" : 0,
          "y" : 13,
          "width" : 8,
          "height" : 6,
          "properties" : {
            "metrics" : [
              ["AWS/AutoScaling", "GroupDesiredCapacity", "AutoScalingGroupName", "${local.ecs_asg_name}", { "region" : "${data.aws_region.current.name}" }],
              [".", "GroupMaxSize", ".", ".", { "region" : "${data.aws_region.current.name}" }],
              [".", "GroupInServiceInstances", ".", ".", { "region" : "${data.aws_region.current.name}" }]
            ],
            "view" : "timeSeries",
            "stacked" : false,
            "region" : "${data.aws_region.current.name}",
            "yAxis" : {
              "left" : {
                "min" : 0
              }
            },
            "title" : "EC2 Instances",
            "period" : 60,
            "stat" : "Average"
          }
        },
        {
          "type" : "metric",
          "x" : 8,
          "y" : 13,
          "width" : 8,
          "height" : 6,
          "properties" : {
            "metrics" : [
              ["AWS/EC2", "CPUUtilization", "AutoScalingGroupName", "${local.ecs_asg_name}", { "region" : "${data.aws_region.current.name}" }],
              [".", "CPUCreditUsage", ".", ".", { "yAxis" : "right", "region" : "${data.aws_region.current.name}" }],
              [".", "CPUCreditBalance", ".", ".", { "yAxis" : "right", "region" : "${data.aws_region.current.name}" }]
            ],
            "view" : "timeSeries",
            "stacked" : false,
            "region" : "${data.aws_region.current.name}",
            "title" : "EC2 CPU",
            "stat" : "Average",
            "period" : 60,
            "yAxis" : {
              "left" : {
                "min" : 0
              },
              "right" : {
                "min" : 0,
                "label" : "CPU Credit Balance",
                "showUnits" : false
              }
            }
          }
        },
        {
          "type" : "text",
          "x" : 0,
          "y" : 12,
          "width" : 24,
          "height" : 1,
          "properties" : {
            "markdown" : "## Autoscale EC2 Metrics - will be empty for Fargate services"
          }
        },
        {
          "type" : "metric",
          "x" : 16,
          "y" : 13,
          "width" : 8,
          "height" : 6,
          "properties" : {
            "metrics" : [
              ["AWS/EC2", "EBSWriteOps", "AutoScalingGroupName", "${local.ecs_asg_name}", { "region" : "${data.aws_region.current.name}" }],
              [".", "EBSReadBytes", ".", ".", { "yAxis" : "right", "region" : "${data.aws_region.current.name}" }],
              [".", "EBSWriteBytes", ".", ".", { "yAxis" : "right", "region" : "${data.aws_region.current.name}" }],
              [".", "EBSReadOps", ".", ".", { "region" : "${data.aws_region.current.name}" }]
            ],
            "view" : "timeSeries",
            "stacked" : false,
            "region" : "${data.aws_region.current.name}",
            "stat" : "Average",
            "period" : 60,
            "yAxis" : {
              "left" : {
                "min" : 0,
                "showUnits" : false,
                "label" : "Operations/sec"
              },
              "right" : {
                "min" : 0
              }
            },
            "title" : "EC2 EBS I/O"
          }
        },
        {
          "type" : "metric",
          "x" : 0,
          "y" : 19,
          "width" : 8,
          "height" : 6,
          "properties" : {
            "metrics" : [
              ["AWS/EC2", "NetworkOut", "AutoScalingGroupName", "${local.ecs_asg_name}", { "yAxis" : "right" }],
              [".", "NetworkPacketsIn", ".", "."],
              [".", "NetworkIn", ".", ".", { "yAxis" : "right" }],
              [".", "NetworkPacketsOut", ".", "."]
            ],
            "view" : "timeSeries",
            "stacked" : false,
            "region" : "${data.aws_region.current.name}",
            "stat" : "Average",
            "period" : 60,
            "title" : "EC2 Network I/O",
            "yAxis" : {
              "left" : {
                "min" : 0,
                "label" : "Packets/sec",
                "showUnits" : false
              },
              "right" : {
                "min" : 0
              }
            }
          }
        }
      ]
    }
  )
}