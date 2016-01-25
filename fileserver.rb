require 'socket'
require 'thread'

STUDENT_ID = "049fab2b9ed8146e9994a921f654febcdd3cd31c28b62db0020a0bbd889ff3f4"
service_kill = false

unless ARGV.length == 2
	print "The correct number of arguments is 2!\n"
	exit
end

ip = ARGV[1]
port = ARGV[0]
server = TCPServer.new(ip, port)
client_queue = Queue.new

Thread.new do
	loop do
		Thread.start(server.accept) do |client|
			client_queue.push(client)
		end
	end
end

workers = (0...2).map do
	Thread.new do
		begin
			while client = client_queue.pop()
				input = client.gets
				if (/HELO \w/).match(input) != nil
					client.puts "#{input}IP:#{ip}\nPort:#{port}\nStudentID:#{STUDENT_ID}\n"
				elsif input == "KILL_SERVICE\n"
					service_kill = true
				end
				client.close
			end
		end
	end
end

while !service_kill
end
