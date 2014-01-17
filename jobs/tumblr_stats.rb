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
  text_feed  = client.posts("malmostartups.tumblr.com",type: 'text',  :limit => 90)
  photo_feed = client.posts("malmostartups.tumblr.com",type: 'photo', :limit => 90)
  quote_feed = client.posts("malmostartups.tumblr.com",type: 'quote', :limit => 90)
  link_feed  = client.posts("malmostartups.tumblr.com",type: 'link',  :limit => 90)

  text_parsed = ParsedTumblr.new(text_feed)
  photo_parsed = ParsedTumblr.new(photo_feed)
  quote_parsed = ParsedTumblr.new(quote_feed)
  link_parsed = ParsedTumblr.new(link_feed)

  dates = text_parsed.posts_per_day +
          photo_parsed.posts_per_day +
          link_parsed.posts_per_day +
          quote_parsed.posts_per_day

  posts_per_day = dates.group_by{|o| o}.map{|group, val| {x: group, y:val.count}}

  sorted = posts_per_day.sort { |x, y| x[:x] <=> y[:x] }
  sorted.pop
  send_event('tumblr_posts_total', current: text_parsed.number_of_posts )
  send_event('tumblr_posts_per_day', points: sorted )

end
class ParsedTumblrPost

  attr_accessor :post
  def initialize(post)
    @post = post
  end

  def date_string
    post["date"]
  end

  def date
    end_of_day(exact_date)
  end

  def exact_date
    DateTime.parse(date_string, "%Y-%m-%d %H:%M:%S GMT")
  end

  def end_of_day(time)
    time.to_date.to_time.to_i + 24*60*60
  end
end

class ParsedTumblr
  attr_accessor :feed

  def initialize(feed)
    @feed = feed
  end

  def posts
    feed["posts"]
  end

  def number_of_posts
    feed["total_posts"]
  end

  def posts_per_day
    dates = posts.map {|post|
      parsed_post = ParsedTumblrPost.new(post)
      parsed_post.date
    }
    dates
  end

end
