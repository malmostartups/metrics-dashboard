#!/usr/bin/env ruby
require 'net/http'
require 'json'

facebook_graph_username = 'malmostartups'

SCHEDULER.every '1m', first_in: 0 do |job|
  http = Net::HTTP.new('graph.facebook.com')
  response = http.request(Net::HTTP::Get.new("/#{facebook_graph_username}"))
  if response.code != '200'
    puts "facebook error (status-code: #{response.code})\n#{response.body}"
  else
    data = JSON.parse(response.body)
    if data['likes']
      send_event('facebook_likes',
                 value: data['likes'])

      send_event('facebook_checkins',
                 current: data['checkins'])

      send_event('facebook_were_here_count',
                 current: data['were_here_count'])

      send_event('facebook_talking_about_count',
                 current: data['talking_about_count'])
    end
  end
end
