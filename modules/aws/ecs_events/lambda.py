import boto3

namespace = "Apres/ECS"
metric_name = "TaskNonZeroExitCode"

def lambda_handler(event, context):
    if event['source'] != 'aws.ecs':
        raise ValueError('Function only supports input from events with a source type of: aws.ecs')

    if event['detail-type'] != 'ECS Task State Change':
        print('This function only cares about events with a detail type of: "ECS Task State Change", ignoring event {}'.format(event['detail-type']))
        return {
            'status': 200,
            'body': 'Ignoring event of type {}'.format(event['detail-type'])
        }

    # Get cluster and task ARNs and names
    cluster_arn = event['detail']['clusterArn']
    cluster_name = cluster_arn.split('/')[-1]
    task_arn = event['detail']['containers'][0]['taskArn']
    task_name = event['detail']['containers'][0]['name']
    # Group is like "service:myservicename"
    service_name = event['detail']['group'].split(':')[-1]

    # create clients
    ecs = boto3.client('ecs')
    cw = boto3.client('cloudwatch')

    # Get the task details
    response = ecs.describe_tasks(cluster=cluster_arn, tasks=[task_arn])

    # exitCode is only there if the task has stopped. We get all events, so need to check if it's there
    # and ignore if it's not.
    try:
      exit_code = response['tasks'][0]['containers'][0]['exitCode']
    except KeyError:
        print('Exit code not found, ignoring this task {task} in cluster {cluster}'.format(
            task=task_name, cluster=cluster_name))
        return {
            'status': 200,
            'body': 'Ignoring event, could not find exitCode for task'
        }

    if exit_code != 0:
        print('Task {task} in cluster {cluster} failed with exit code: {exit_code}'.format(
            task=task_name, cluster=cluster_name, exit_code=exit_code))
        # Set the counter with the cluster, task and service as dimensions
        # No need to increment, just add 1. CW will handle the increments.
        cw.put_metric_data(
            Namespace=namespace,
            MetricData=[
                {
                    'MetricName': metric_name,
                    'Dimensions': [
                        {
                            'Name': 'Cluster',
                            'Value': cluster_name
                        },
                        {
                            'Name': 'Task',
                            'Value': task_name
                        },
                        {
                            'Name': 'Service',
                            'Value': service_name
                        }
                    ],
                    'Value': 1,
                    'Unit': 'Count'
                }
            ]
        )

    return {
        'status': 200,
        'body': 'Success'
    }