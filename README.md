![Architecture Image](https://splash-brothers.s3.us-west-1.amazonaws.com/splash_brothers_architecture_v2a.png)

# Splash Brothers

Splash Brothers is a serverless web application created with a number of AWS cloud services that gathers
and provides data for the top 3-point shooters for a specific team at any point during the 2022-2023 season.
The frontend is a React web app, while the backend lambdas are written in Ruby and uses DynamoDB to store data.
Users can typically find the up-to-date, season leaders in 3-pointers on sports websites, such as ESPN or
CBS Sports, but it's a challenge to identify the team leaders at any point during the season. This app solves
this problem by providing a way to track a team's top 3-point shooters throughout the entire season.

## Features Overview

![React Web App Image](https://splash-brothers.s3.us-west-1.amazonaws.com/react_web_app.png)

-   React web app (using Material UI components) to query and display data
-   Public API endpoint to fetch the team leaders in 3 pointers on a specific date
-   Private API endpoint to manually invoke the data scraping process

## Scrape Data

### Workflow

1. User makes a POST request to scrape the data on a given date
2. API Gateway accepts request and calls authorizer to return an IAM policy
3. Given a valid policy, API Gateway endpoint triggers the Invoker Lambda
4. Invoker Lambda finds all games for the given date and sends a SNS for each boxscore URL
5. A Scraper Lambda scrapes all game log data for each player on both teams and stores the data in DynamoDB

The data scraping process is triggered by a private API endpoint via AWS API Gateway. The user must specify a date
and an authorization token in the request. When the client makes a request, the API Gateway uses a Lambda authorizer
to check if the authentication token in the request is valid. If so, the authorizer generates a policy that grants
the client access to the API endpoint and then executes the method. However, if the authentication token is invalid,
the authorizer will deny the client access by returning a 403 HTTP status code.

If the request is valid, the API Gateway triggers the [Invoker Lambda](lambda_functions/splash_brothers_game_date_invoker),
which will scrape all the boxscore URLs on the given date and then send a SNS Notification for each URL to a
different lambda, [Data Scraper Lambda](lambda_functions/splash_brothers_game_data_scraper). The Data Scraper Lambda
scrapes the game log data for each player on both teams and stores the data in DynamoDB.

```
curl 'https://<YOUR-API-GATEWAY-ID>.execute-api.us-west-1.amazonaws.com/v1/team-stats/scrape' \
  -X POST \
  -H 'Content-Type: application/json' \
  -H 'authorization: <AUTH-TOKEN>' \
  -d '{"game_date":"<YYYY-MM-DD>"}'
```

To provide greater detail about API Gateway and how it handles a request, it needs to transform the raw data in the
payload so that it can be interpreted by the Invoker Lambda. This data transformation can be done with a mapping
template, which I have written in Velocity Template Language (VTL) for `application/json`:

```
#set($inputRoot = $input.path('$'))
{
  "game_date" : "$inputRoot.game_date"
}
```

## Fetch Data

### Workflow

1. User uses the React web app and runs a query (or makes a direct request)
2. API Gateway accepts request and makes integration request to DynamoDB
3. DynamoDB queries for data
4. API Gateway returns the data to the client

There is a public API endpoint that allows a user to fetch a team's top 3-point shooters on a given date.
The API endpoint makes an integration request to fetch the appropriate data from DynamoDB.

```
curl 'https://<YOUR-API-GATEWAY-ID>.execute-api.us-west-1.amazonaws.com/v1/team-stats/<TEAM>?date=<YYYY-MM-DD>' \
  -X GET \
  -H 'Content-Type: application/json'
```

`<TEAM>` must be one of the following:
`ATL`, `BKN`, `BOS`, `CHA`, `CHI`, `CLE`, `DAL`, `DEN`, `DET`, `GS`, `HOU`, `IND`, `LAC`, `LAL`, `MEM`,
`MIA`, `MIL`, `MIN`, `NO`, `NY`, `OKC`, `ORL`, `PHI`, `PHO`, `POR`, `SA`, `SAC`, `TOR`, `UTA`, `WAS`

The API endpoint returns the results in JSON format. For example,

```
{
    "team": "GS",
    "date": "2023-04-20",
    "players": [
         {
            "player_id": "1647559",
            "player_name": "K. Thompson",
            "games_played": 69,
            "season_3fga": 731,
            "season_3fgm": 301
        },     {
            "player_id": "1685204",
            "player_name": "S. Curry",
            "games_played": 56,
            "season_3fga": 639,
            "season_3fgm": 273
        },     {
            "player_id": "2892690",
            "player_name": "J. Poole",
            "games_played": 82,
            "season_3fga": 637,
            "season_3fgm": 214
        },     {
            "player_id": "2203519",
            "player_name": "D. DiVincenzo",
            "games_played": 72,
            "season_3fga": 378,
            "season_3fgm": 150
        },     {
            "player_id": "2135571",
            "player_name": "A. Wiggins",
            "games_played": 37,
            "season_3fga": 225,
            "season_3fgm": 89
        }
    ]
}
```

API Gateway uses the following mapping template to transform the payload in the client request
so that DynamoDB can process the request:

```
{
    "TableName": "player-game-stats",
    "IndexName": "game_date_cumulative_fg3m-index",
    "KeyConditionExpression": "team = :team and game_date_cumulative_fg3m <= :date",
    "ExpressionAttributeValues": {
        ":team": {
            "S": "$input.params('team_key')"
        },
        ":date": {
            "S": "$input.params('date')#999999"
        }
    },
    "ProjectionExpression": "game_date_player_uid, game_date, player_id, player_name, games_played, cumulative_fg3a, cumulative_fg3m",
    "ScanIndexForward": false,
    "Limit": 10
}
```

Similarly, DynamoDB returns data in a format that's not expected by the frontend. Hence, a mapping template is required to
map the payload from the integration response to the corresponding method response.

```
#set($inputRoot = $input.path('$'))
{
    "team": "$input.params('team_key')",
    "date": "$input.params('date')",
    "players": [
        #foreach($elem in $inputRoot.Items) {
            "player_id": "$elem.player_id.S",
            "player_name": "$elem.player_name.S",
            "games_played": $elem.games_played.N,
            "season_3fga": $elem.cumulative_fg3a.N,
            "season_3fgm": $elem.cumulative_fg3m.N
        }#if($foreach.hasNext),#end
    #end
    ]
}
```
