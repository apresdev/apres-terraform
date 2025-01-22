# Testing Hints

Running the tests can take more than two hours because of the amount of time it takes to build and tear down
a database cluster.

To test this locally without constantly rebuilding everything, do the following:
1. Set the environment variable `TESTING_DO_NOT_DESTROY=true`
2. Set the environment variable `TESTING_VPC_ENV_TAG=Sandbox`, assuming you're testing in the Sandbox.
3. Run your tests, investigate, rewrite tests, etc.
4. Once you are satisified with your test, unset the `TESTING_DO_NOT_DESTROY` environment variable and run the
   tests once more, to destroy the AWS resources, else they'll be left around!

An example test command might look like:

```
AWS_PROFILE=apres-sandbox TESTING_DO_NOT_DESTROY=true TESTING_VPC_ENV_TAG=Sandbox go test -timeout 240m
```

Remember: Cleanup after you're done! (step 4)