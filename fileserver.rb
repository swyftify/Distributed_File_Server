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
					inputList = input.split(" ")
					inputList.shift
					path = inputList.shift
					if File.exist?("#{path}") == false
						client.puts "No file or directory"
					elsif File.exist?("#{path}") == true
						client.puts "========= BEGIN ========="
						File.open("#{path}", "r") do |f|
							f.each_line do |line|
								client.puts("#{line}")
							end
						end
						client.puts "========= END ========="
						client.puts "#{File.size("#{path}")}"
					end
				elsif(/WRITE \w/).match(input) != nil
					inputList = input.split(" ")
					inputList.shift
					path = inputList.shift
					textToWrite = inputList.join(" ")
					if File.exist?("#{path}") == false
						file = File.new("#{path}", "a")
						file.write("#{textToWrite}\n")
						file.close
					elsif File.exist?("#{path}") == true
						file = File.open("#{path}", "a")
						file.write("#{textToWrite}\n")
						file.close
					end
				end
				client.close
			end
		end
	end
end

while !service_kill
end




