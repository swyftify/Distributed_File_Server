require 'socket'
require 'thread'

MTU = 1500

STUDENT_ID = "049fab2b9ed8146e9994a921f654febcdd3cd31c28b62db0020a0bbd889ff3f4"
service_kill = false
semaphore = Mutex.new

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
				if (/HELO \w/).match(input) != nil
					client.puts "#{input}IP:#{ip}\nPort:#{port}\nStudentID:#{STUDENT_ID}\n"
				elsif input == "KILL_SERVICE\n"
					service_kill = true
				elsif(/READ \w/).match(input) != nil
					inputList = input.split(" ")
					inputList.shift
					path = inputList.shift
					if File.exist?("#{path}") == false
						client.puts "No file or directory"
					elsif File.exist?("#{path}") == true
						client.puts "Sending file of size #{File.size("#{path}")} bytes"
						File.open("#{path}", "r") do |f|
							while chunk = f.read(MTU)
								client.write(chunk)
							end
							puts "Sent"

						end
	
					end
				elsif(/LOAD \w/).match(input) != nil
                    puts "LOAD Command issued"
					inputList = input.split(" ")
					inputList.shift
					path = inputList.shift
                    puts "#{path}" 
				    File.open("#{path}", "a") do |file|
                        puts "Reading from client"
						while chunk = client.read(MTU)
                            puts "READING"
							file.write(chunk)
                            puts "WRITING"
						end
						puts "File updated"
					end
				end
				client.close
			end
		end
	end
end

while !service_kill
end




