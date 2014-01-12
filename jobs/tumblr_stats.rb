#!/usr/bin/env ruby
require 'tumblr_client'
require 'awesome_print'
# The url you are tracking
Tumblr.configure do |config|
  config.consumer_key = ENV["TUMBLR_CONSUMER_KEY"]
  config.consumer_secret = ENV["TUMBLR_CONSUMER_SECRET"]
  config.oauth_token = ENV["TUMBLR_OAUTH_TOKEN"]
  config.oauth_token_secret = ENV["TUMBLR_OAUTH_TOKEN_SECRET"]
end

SCHEDULER.every '10m', :first_in => 0 do

  client = Tumblr::Client.new
  posts = client.posts("malmostartups.tumblr.com")

  count = posts["total_posts"]
  send_event('tumblr_posts', current: count )
end

