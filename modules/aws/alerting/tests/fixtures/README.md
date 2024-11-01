# Alerting Tests

These tests are not automated, in part because the validation requires Slack and Teams
API access and manual configuration.

To run the tests against the Sandbox environment:

1. Init the terraform state:
```bash
tofu init
```

2. Run it against two regions:
```bash
AWS_PROFILE=apres-sandbox AWS_REGION=us-east-2 tofu apply -state terraform.us-east-2.tfstate
AWS_PROFILE=apres-sandbox AWS_REGION=us-west-2 tofu apply -state terraform.us-west-2.tfstate
```

3. Navigate to the Chatbot console, send test messages to each configuration, and check for results
   in the `#aws-sandbox-us-east-2` and `#aws-sandbox-us-west-2` channels in both Teams and Slack.

4. Delete the configurations:
```bash
AWS_PROFILE=apres-sandbox AWS_REGION=us-east-2 tofu destroy -state terraform.us-east-2.tfstate
AWS_PROFILE=apres-sandbox AWS_REGION=us-west-2 tofu destroy -state terraform.us-west-2.tfstate
```

