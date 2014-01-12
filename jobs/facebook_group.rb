#!/usr/bin/env ruby
require 'koala'
require 'awesome_print'

groupid = '176366152561358'
oauth_access_token = ENV['FACEBOOK_ACCESS_TOKEN']
SCHEDULER.every '10m', :first_in => 0 do
  @graph = Koala::Facebook::API.new(oauth_access_token)

  profile = @graph.get_object(groupid)
  feed = @graph.get_connections(groupid, "feed")
  send_event('facebook_group_posts', current: feed.count )
end

