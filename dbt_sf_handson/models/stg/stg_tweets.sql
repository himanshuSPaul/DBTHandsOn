WITH RAW_TWEETS AS (
    SELECT * FROM {{ source('raw', 'raw_tweets') }}
)

SELECT  ID         AS TWEET_ID, 
        USER_ID    AS TWEET_USER_ID, 
        TWEETED_AT AS TWEETED_AT, 
        CONTENT    AS TWEET_CONTENT
FROM RAW_TWEETS