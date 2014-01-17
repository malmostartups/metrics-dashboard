#!/usr/bin/env ruby
require 'net/http'

instagram_username = 'malmostartups'

SCHEDULER.every '10m', first_in: 0 do |job|
  http = Net::HTTP.new('instagram.com')
  response = http.request(Net::HTTP::Get.new("/#{instagram_username}"))

  if response.code != '200'
    puts "instagram error (status-code: #{response.code})\n#{response.body}"
  else

    regex = /"counts":{"media":(\d+),"followed_by":(\d+),"follows":(\d+)}/
    match = regex.match(response.body)

    user_info = [
      {
        label: 'Followers',
        value: match[2].to_i
      },
      {
        label: 'Following',
        value: match[3].to_i
      },
      {
        label: 'Photos',
        value: match[1].to_i
      }
    ]

    if defined?(send_event)
      send_event('instagram_userinfo',  items: user_info)
    else
      print user_info
    end

    # send every list item as a single event
    user_info.each do |element|
      varname = 'instagram_user_' + element[:label].downcase
      if defined?(send_event)
        send_event(varname, current: element[:value])
      else
        print "#{varname}: #{element[:value]}\n"
      end
    end

  end
end
