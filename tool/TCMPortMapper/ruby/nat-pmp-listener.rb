#!/usr/bin/env ruby
require 'socket'
require 'ipaddr'

port  = 5351

print "Listening for NAT-PMP public IP changes:\n"

socket = UDPSocket.new
socket.setsockopt(Socket::SOL_SOCKET, Socket::SO_REUSEADDR, true)
socket.setsockopt(Socket::SOL_SOCKET, Socket::SO_REUSEPORT, true)
socket.bind("224.0.0.1",5351)
addr  = '0.0.0.0'
host  = Socket.gethostname
# socket.setsockopt(Socket::IPPROTO_IP, Socket::IP_ADD_MEMBERSHIP, mreq)
loop do
  data, sender = socket.recvfrom(100)
  host = sender[3]
  received = data.unpack('CCnNN')
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
  print "#{Time.now} #{host}: Received new Public Address packet: IP #{IPAddr.ntop(data[8..12])} - Vers= #{received[0]}, OP = #{received[1]}, ResultCode = #{received[2]}, Epoch Seconds = #{received[3]}\n"
end