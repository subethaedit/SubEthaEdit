#!/usr/bin/env ruby

require 'uri'

input = $stdin.read

uri_matches = URI.extract(input)
uri_to_open = false
if uri_matches.length == 1
  uri_to_open = uri_matches[0]
else
  position_in_line = ARGV[0].to_i
  input.gsub(URI.regexp) do |match|
    if (position_in_line>=$~.offset(0)[0] && position_in_line<=$~.offset(0)[1])
      uri_to_open = match
      break
    end
  end
end

if uri_to_open
  `open "#{uri_to_open}"`
end