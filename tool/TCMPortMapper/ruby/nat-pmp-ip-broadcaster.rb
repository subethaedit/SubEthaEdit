#!/usr/bin/env ruby
require 'socket'
require 'ipaddr'

port  = 5351
#   A compatible NAT gateway MUST generate a response with the following
#   format:
#
#    0                   1                   2                   3
#    0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
#   +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
#   | Vers = 0      | OP = 128 + 0  | Result Code                   |
#   +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
#   | Seconds Since Start of Epoch                                  |
#   +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
#   | Public IP Address (a.b.c.d)                                   |
#   +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+


uni_socket = UDPSocket.new
uni_socket.connect("224.0.0.1",port)
secondsSinceStart = 123
publicIPAddress = IPAddr.new("222.66.55.55").to_i

loopCount = 0

while true do
  uni_socket.send([0,128,0,secondsSinceStart+loopCount,publicIPAddress+loopCount].pack('CCnNN'),0)
  sleep 10
#  loopCount += 1
end
