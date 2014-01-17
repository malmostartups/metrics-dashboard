#!/usr/bin/env ruby
require 'koala'
require 'awesome_print'
require 'pry'

groupid = '176366152561358'
oauth_access_token = ENV['FACEBOOK_ACCESS_TOKEN']
SCHEDULER.every '10m', first_in: 0 do
  @graph = Koala::Facebook::API.new(oauth_access_token)

  # profile = @graph.get_object(groupid)
  feed = @graph.get_connections(groupid, 'feed')

  parsed = ParsedFeed.new(feed)

  likes = parsed.likes_per_day_sorted
  likes.pop
  comments =  parsed.comments_per_day_sorted
  comments.pop

  send_event('facebook_likes_per_post', points: likes)
  send_event('facebook_comments_per_post', points: comments)
  send_event('facebook_group_posts', current: feed.count)
end

class ParsedPost
  attr_accessor :post

  def initialize(post)
    @post = post
  end

  def date
    exact_date = DateTime.parse(date_string, '%Y-%m-%d%H:%M:%S')
    end_of_day(exact_date)
  end

  def end_of_day(date)
    date.to_date.to_time.to_i + 24 * 60 * 60
  end

  def date_string
    post['created_time']
  end

  def post_likes
    if post['likes']
      post['likes'].count
    else
      0
    end
  end

  def total_comments
    comments.count
  end

  def comments
    if post && post['comments']
      post['comments']['data']
    else
      []
    end
  end

  def comment_likes
    comments.reduce(0) do|sum, comment|
      sum + comment['like_count'].to_i
    end
  end

  def total_likes
    comment_likes + post_likes
  end
end

class ParsedFeed
  attr_accessor :feed

  def initialize(feed)
    @feed = feed
  end

  def likes_per_post
    feed.map do|post|
      parsed_post = ParsedPost.new(post)
      { day: parsed_post.date, count: parsed_post.total_likes }
    end
  end

  def likes_grouped_by_day
    likes_per_post.group_by { |post| post[:day] }
  end

  def likes_per_day
    likes_grouped_by_day.map do |key, day|
      count = day.reduce(0) { |sum, post| sum + post[:count] }
      { x: key, y: count }
    end
  end

  def likes_per_day_sorted
    likes_per_day.sort { |x, y| x[:x] <=> y[:x] }
  end

  def comments_per_post
    feed.map do |post|
      parsed_post = ParsedPost.new(post)
      { day: parsed_post.date, count: parsed_post.total_comments }
    end
  end

  def comments_grouped_by_day
    comments_per_post.group_by { |post| post[:day] }
  end

  def comments_per_day
    comments_grouped_by_day.map do |key, day|
      count = day.reduce(0) { |sum, post| sum + post[:count] }
      { x: key, y: count }
    end
  end

  def comments_per_day_sorted
    comments_per_day.sort { |x, y| x[:x] <=> y[:x] }
  end
end
