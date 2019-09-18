#  Install Requried Packages
install.packages("SnowballC")
install.packages("tm")
install.packages("twitteR")
install.packages("syuzhet")
install.packages("tidytext")
install.packages("glue")
install.packages("data.table")


# Load Requried Packages
library(twitteR)
library(wordcloud)
library(tm)
library(magrittr)
library(tidytext)
library(glue)
library(stringr)
library(dplyr)
library(tidyr)
library(scales)
library(tidyverse)
library(data.table)


# REMOVED TWITTER KEYS


setup_twitter_oauth(consumer_key, consumer_secret, access_token, access_secret)

dt_top10 <- dt_top20[order(-total_points),head(.SD,10)]

sentimentP <- tibble()

for (i in 1:nrow(dt_top10)) {
  Sys.sleep(100)
  loc <- paste(dt_top10[i,]$lat,',',dt_top10[i,]$lng,',10mi',sep='')
  t_tweets <- searchTwitter("", n = 500, geocode=loc)
  
  df_tweets <- tibble(text = sapply(t_tweets, function(x) x$getText()))
  
  df_tweets <- gsub("\\$", "", df_tweets) 
  tokens <- tibble(text = df_tweets) %>% unnest_tokens(word, text)
  
  sentiment <- tokens %>%
    inner_join(get_sentiments("bing")) %>% 
    count(sentiment) %>% 
    spread(sentiment, n, fill = 0) %>% 
    mutate(sentiment = positive - negative) 
  sentimentP <- rbind(sentimentP, sentiment$positive / (sentiment$positive + sentiment$negative))
}

dt_top10$posSentiment <- sentimentP

#Table ranking cities based on social media sentiment analysis
dt_topSent <- select(dt_top10, state_id, city_ascii, posSentiment)
dt_topSent <- dt_topSent[order(-posSentiment),]

write.csv(dt_topSent, file = "topSent.csv")

