require 'socket'

s = TCPSocket.open('localhost', 2000)

while line = s.gets   # Read lines from the socket
  puts line.chop      # And print with platform line terminator
end
s.close  