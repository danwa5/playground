# Lambda Function: splash_brothers_invoker

This lambda function will invoke the `splash_brothers_data_scraper` lambda function
for every member of the Splash Brothers by sending a SNS notification.

## Build

Run the build script, which will generate a `lambda_function.zip` file.

```
./bin/build.sh
```

## Deploy

### Upload to AWS Lambda

**Option 1** AWS Lambda Web Interface

1. Click on the Upload From dropdown menu
2. Click on .zip file and select the `lambda_function.zip` file from the build process.

**Option 2** AWS Command Line Interface

```
aws lambda update-function-code --function-name splash_brothers_invoker --zip-file fileb://lambda_function.zip
```

### Configure environment variables

The `GEM_PATH` environment variable must be set to `/opt/ruby/2.7.0`.
The `AWS_SNS_TOPIC_ARN` env var must be set to the ARN of the topic subscription.

### Configure EventBridge trigger

In the Lambda web interface, create a scheduld-based rule and add the ARN for this lambda as the target.
