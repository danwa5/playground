![My Remote Image](https://splash-brothers.s3.us-west-1.amazonaws.com/splash_brothers_architecture_v2.png)

# Splash Brothers

Splash Brothers is a serverless ruby web application created with a number of AWS cloud services that gathers
and provides data for the top 3-point shooters for a specific team at any point in a season. Users can typically
find the season leaders in 3-pointers on sports websites, such as ESPN or CBS Sports, but it's a challenge to
identify the team leaders at any point within a season. This app solves this problem and will allow users to track
a team's top 3-point shooters throughout the entire season.

## Features Overview

-   Private API endpoint to manually invoke the data scraping process
-   Public API endpoint to fetch the team leaders in 3 pointers on a specific date

## Scrape Data

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

## Fetch Data

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

The API endpoint will return the results in JSON format. For example,

```
{
    "stats": [
         {
            "last_game": "2023-03-31",
            "player_id": "1647559",
            "player_name": "K. Thompson",
            "games_played": 66,
            "season_3fga": 696,
            "season_3fgm": 285
        },     {
            "last_game": "2023-03-31",
            "player_id": "1685204",
            "player_name": "S. Curry",
            "games_played": 52,
            "season_3fga": 595,
            "season_3fgm": 257
        },     {
            "last_game": "2023-03-31",
            "player_id": "2892690",
            "player_name": "J. Poole",
            "games_played": 78,
            "season_3fga": 611,
            "season_3fgm": 205
        },     {
            "last_game": "2023-03-31",
            "player_id": "2203519",
            "player_name": "D. DiVincenzo",
            "games_played": 68,
            "season_3fga": 355,
            "season_3fgm": 139
        },     {
            "last_game": "2023-03-31",
            "player_id": "2135571",
            "player_name": "A. Wiggins",
            "games_played": 37,
            "season_3fga": 225,
            "season_3fgm": 89
        },     {
            "last_game": "2023-03-31",
            "player_id": "2268636",
            "player_name": "A. Lamb",
            "games_played": 58,
            "season_3fga": 196,
            "season_3fgm": 73
        },     {
            "last_game": "2023-03-31",
            "player_id": "26602407",
            "player_name": "J. Kuminga",
            "games_played": 63,
            "season_3fga": 138,
            "season_3fgm": 49
        },     {
            "last_game": "2023-03-31",
            "player_id": "3177810",
            "player_name": "M. Moody",
            "games_played": 60,
            "season_3fga": 123,
            "season_3fgm": 42
        },     {
            "last_game": "2023-03-31",
            "player_id": "2103346",
            "player_name": "J. Green",
            "games_played": 56,
            "season_3fga": 110,
            "season_3fgm": 42
        },     {
            "last_game": "2023-03-31",
            "player_id": "1992792",
            "player_name": "D. Green",
            "games_played": 69,
            "season_3fga": 123,
            "season_3fgm": 38
        }
    ]
}
```
