require 'twitter'

#### Get your twitter keys & secrets:
#### https://dev.twitter.com/docs/auth/tokens-devtwittercom

client = Twitter::REST::Client.new do |config|
  config.consumer_key = ENV['TWITTER_CONSUMER_KEY']
  config.consumer_secret = ENV['TWITTER_CONSUMER_SECRET']
  config.oauth_token = ENV['TWITTER_OAUTH_TOKEN']
  config.oauth_token_secret = ENV['TWITTER_OAUTH_SECRET']
end

twitter_username = 'malmostartups'

MAX_USER_ATTEMPTS = 10
user_attempts = 0

SCHEDULER.every '10m', :first_in => 0 do |job|
  begin
    tw_user = client.user("#{twitter_username}")
    if tw_user
        tweets = tw_user.statuses_count
        followers = tw_user.followers_count
        following = tw_user.friends_count

        send_event('twitter_user_tweets', current: tweets)
        send_event('twitter_user_followers', value: followers)
        send_event('twitter_user_following', current: following)

    end
  rescue Twitter::Error => e
    user_attempts = user_attempts +1
    puts "Twitter error #{e}"
    puts "\e[33mFor the twitter_user widget to work, you need to put in your twitter API keys in the jobs/twitter_user.rb file.\e[0m"
    sleep 5
    retry if(user_attempts < MAX_USER_ATTEMPTS)
  end
end
