library(curlconverter)
library(jsonlite)
library(httr)
library(glue)
library(ggplot2)
library(dplyr)

################################################
# Sends a get request to mlb servers and retreives
# the standings for the AL, NL and merges them together
# Param: date - date object of date to be retreived
# Returns: df - entire league standings, ordered by team_name
#################################################
get_standings_by_date <- function(date) {
  cmd <- glue("curl 'http://lookup-service-prod.mlb.com/lookup/json/named.historical_standings_schedule_date.bam?\\
            season={format(game_date, '%Y')}&\\
              game_date=%27{format(game_date, '%Y/%m/%d')}%27&\\
              sit_code=%27h0%27&\\
              league_id=103&\\
              league_id=104&\\
              all_star_sw=%27N%27\\
              &version=48' \\
              -H 'Origin: http://mlb.mlb.com' \\
              -H 'Accept-Encoding: gzip, deflate' \\
              -H 'Accept-Language: en-US,en;q=0.9' \\
              -H 'User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_11_6) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/67.0.3396.87 Safari/537.36' \\
              -H 'Accept: text/plain, */*; q=0.01' \\
              -H 'Referer: http://mlb.mlb.com/mlb/standings/index.jsp' \\
              -H 'Connection: keep-alive' \\
              -H 'DNT: 1' --compressed", game_date=date)
  
  straight <- straighten(cmd)
  
  res <- make_req(straight)
  json_response <- toJSON(content(res[[1]](), as="parsed"), auto_unbox = TRUE, pretty=TRUE)
  parsed <- fromJSON(json_response)
  
  leagues <- parsed$historical_standings_schedule_date$standings_all_date_rptr$standings_all_date
  leagues.al <- leagues$queryResults$row[[2]] # League id 104 == AL
  leagues.nl <- leagues$queryResults$row[[1]] # League id 103 == NL
  leagues.merged <- rbind(leagues.al, leagues.nl)
  data <- leagues.merged %>%
    select(team_abbrev, w, l, pct, playoff_odds) %>%
    arrange(team_abbrev)
  return(data)
}

start <- as.Date("29-03-18",format="%d-%m-%y")
# Doesn't exist for today's date
end   <- Sys.Date() - 1

theDate <- start

while (theDate <= end) {
  data <- get_standings_by_date(theDate)
  
  # If it's the first iteration, create the season dataframe to hold all data
  if(theDate == start) {
    season <- data %>% select(team_abbrev)
    # Create the image url from ESPN's CDN with the team abbreviation
    data <- data %>% mutate(image_url=glue(
      "http://a.espncdn.com/combiner/i?img=/i/teamlogos/mlb/500/{tolower(team_abbrev)}.png&h=100&w=100"
      ))
    season['image_url'] <- data$image_url
  }
  
  win_per <- select(data, pct)
  # Append the standings as of theDate
  season[as.character(theDate)] <- win_per
  theDate <- theDate + 1                    
}

# Export
write.csv(season, "horserace.csv", row.names = FALSE)
