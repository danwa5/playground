![My Remote Image](https://splash-brothers.s3.us-west-1.amazonaws.com/splash_brothers_architecture.png)

# Splash Brothers

Splash Brothers is a serverless ruby web application created with a number of AWS cloud services that gathers
and provides 3 point game data for each member of the Golden State Warriors' Splash Brothers - Steph Curry
and Klay Thompson. I've included Jordan Poole as well since his playing style befits the Baby Splash Brother
moniker.

## Features Overview

-   Daily cron job to scrape game data for each player
-   Private API endpoint to manually invoke the data scraping process for a player
-   Public API endpoint to fetch game data for a player

## Scrape Data

There are 2 methods to invoke the data scraping process. The first method uses an AWS EventBridge rule to create
a daily cron job that triggers an [Invoker Lambda](lambda_functions/splash_brothers_invoker), which will send a
SNS Notification for each player to a second [Data Scraper Lambda](lambda_functions/splash_brothers_data_scraper).
The Data Scraper Lambda will then scrape game log data for a player from https://www.cbssports.com and store the
data in DynamoDB.

The second method utilizes a private API endpoint via AWS API Gateway. This allows an authenticated user
to manually invoke the data scraping process for a player.

```
curl 'https://<YOUR-API-GATEWAY-ID>.execute-api.us-west-1.amazonaws.com/v1/scrape' \
  -X POST \
  -H 'Content-Type: application/json' \
  -d '{"player_name":"steph-curry"}' \
  --user <USER-TOKEN> \
  --aws-sigv4 "aws:amz:us-west-1:execute-api"
```

## Fetch Data

There is a public API endpoint that allows a user to fetch game data within a date range for a specific
Splash Brothers player. The API endpoint makes an integration request to fetch the appropriate data from
DynamoDB. The valid player IDs are `steph-curry`, `klay-thompson`, and `jordan-poole`.

```
curl 'https://<YOUR-API-GATEWAY-ID>.execute-api.us-west-1.amazonaws.com/v1/player-stats/<PLAYER-ID>?from_date=<YYYY-MM-DD>&to_date=<YYYY-MM-DD>' \
  -X GET \
  -H 'Content-Type: application/json'
```

The API endpoint will return a player's game data in JSON format. For example,

```
{
    "stats": [
        {
            "game_date": "2023-01-10",
            "opponent": "vs PHO",
            "3fga": 15,
            "3fgm": 5
        },
        {
            "game_date": "2023-01-13",
            "opponent": "@SA",
            "3fga": 7,
            "3fgm": 2
        }
    ]
}
```
