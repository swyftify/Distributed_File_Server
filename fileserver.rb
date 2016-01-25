require 'socket'
require 'thread'

SIZE = 1024 * 1024 * 10

STUDENT_ID = "049fab2b9ed8146e9994a921f654febcdd3cd31c28b62db0020a0bbd889ff3f4"
service_kill = false
semaphore = Mutex.new

/unless ARGV.length == 2
	print "The correct number of arguments is 2!\n"
	exit
end

ip = ARGV[1]
port = ARGV[0]
/
server = TCPServer.new('localhost', 2005)
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
				if(/READ \w/).match(input) != nil
					client.puts "READ ISSUED"
				elsif(/WRITE \w/).match(input) != nil
					path = input.split(" ")
					if File.exist?("#{path[1]}") == false
						file = File.new("#{path[1]}", "w+")
						file.puts("Testing")
						file.close	
						puts "Sending File"
				    	while chunk = file.read(SIZE)
				    		client.write(chunk)
				    	end
					  	puts "Finished sending"
					end
				end
				client.close
			end
		end
	end
end

while !service_kill
end




