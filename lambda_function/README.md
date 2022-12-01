# Lambda Function: splash_brothers_data_scraper

This lambda function will scrape the game log pages on https://www.cbssports.com
for Steph Curry, Klay Thompson, and Jordan Poole and store their 3 point game data
in a DynamoDB table. This data will be available through an AWS Gateway REST Api
endpoint.

## Build

Run the build script, which will generate a `lambda_function.zip` file.

```
./bin/build.sh
```

## Lambda Layers

This lambda function uses both the [HTTParty](../lambda_layers/httparty/) and
[Nokogiri](../lambda_layers/nokogiri/) lambda layers. It uses HTTParty to make
a request for a web page and parses the response as JSON. Next, it uses Nokogiri
to parse the HTML, return a DOM representation of the document, and then allow us
to search for and extract specific elements.

Make sure to add both layers to the latest version of the lambda function.

## Deploy

### Upload to AWS Lambda

**Option 1** AWS Lambda Web Interface

1. Click on the Upload From dropdown menu
2. Click on .zip file and select the `lambda_function.zip` file from the build process.

**Option 2** AWS Command Line Interface

```
aws lambda update-function-code --function-name splash_brothers_data_scraper --zip-file fileb://lambda_function.zip
```

### Configure environment variable

The `GEM_PATH` environment variable must be set to `/opt/ruby/2.7.0`.

### Configure API Gateway trigger

In the Lambda web interface, add the API ID for your API endpoint to invoke the lambda (i.e. /v1/scrape)
