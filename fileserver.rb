require 'socket'
require 'thread'
require 'openssl'
require 'base64'

MTU = 1500

STUDENT_ID = "049fab2b9ed8146e9994a921f654febcdd3cd31c28b62db0020a0bbd889ff3f4"
service_kill = false
$public_key = OpenSSL::PKey::RSA.new(File.read("public_key.pem"))
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
					authServiceSock = TCPSocket.open 'localhost', 2006
					authServiceSock.print("KILL_SERVICE")
					dirSocket = TCPSocket.open('localhost', 2008)
					dirSocket.print("KILL_SERVICE")
					lock_socket = TCPSocket.open('localhost', 2007)
					lock_socket.print("KILL_SERVICE")
					service_kill = true
				elsif(/READ \w/).match(input) != nil
					inputList = input.split(" ")
					inputList.shift
					path = inputList.shift
					dirSocket = TCPSocket.open('localhost', 2008)
					directoryRequest = "GET #{path}"
					encryptedDirRequest = Base64.encode64($public_key.public_encrypt(directoryRequest))
					dirSocket.print("GET #{encryptedDirRequest}\n")
					if File.exist?("#{path}") == false
							puts "No file #{path} exists"
							client.puts(false)
							break
					elsif File.exist?("#{path}") == true
						lock_socket = TCPSocket.open('localhost', 2007)
						message_lock = "REQUEST #{path}"
						encrypted_string = Base64.encode64($public_key.public_encrypt(message_lock))
						lock_socket.print("REQUEST #{encrypted_string}\n")
						status = lock_socket.gets()
						File.open("#{path}", "r") do |f|
							while chunk = f.read(MTU)
								client.write(chunk)
							end
							puts "Sent"
						end
						lock_socket = TCPSocket.open('localhost', 2007)
						message_lock = "RELEASE #{path}"
						encrypted_string = Base64.encode64($public_key.public_encrypt(message_lock))
						lock_socket.print("RELEASE #{encrypted_string}")
					end
				elsif(/LOAD \w/).match(input) != nil
					inputList = input.split(" ")
					inputList.shift
					path = inputList.shift
					lock_socket = TCPSocket.open('localhost', 2007)
					message_lock = "REQUEST #{path}"
					encrypted_string = Base64.encode64($public_key.public_encrypt(message_lock))
					lock_socket.print("REQUEST #{encrypted_string}\n")
					status = lock_socket.gets()
					if File.exist?("#{path}") == false
						File.open("#{path}", "a") do |file|
			       				puts "Reading from client"
							while chunk = client.read(MTU)
								file.write(chunk)
							end
							puts "File updated"
						end
					elsif File.exist?("#{path}") == true
						File.delete("#{path}")
						File.open("#{path}", "a") do |file|
			       				puts "Reading from client"
							while chunk = client.read(MTU)
								file.write(chunk)
							end
							puts "File updated"
						end
					end
					lock_socket = TCPSocket.open('localhost', 2007)
					message_lock = "RELEASE #{path}"
					encrypted_string = Base64.encode64($public_key.public_encrypt(message_lock))
					lock_socket.print("RELEASE #{encrypted_string}")
					dirSocket = TCPSocket.open('localhost', 2008)
					directoryRequest = "ADD IP: localhost " + "PORT: 2008 " + "FILE: " + "#{path}"
					encryptedDirRequest = Base64.encode64($public_key.public_encrypt(directoryRequest))	
					dirSocket.print("ADD #{encryptedDirRequest}")
				end
				authServiceSock.close
				dirSocket.close
				lock_socket.close
				client.close
			end
		end
	end
end

while !service_kill
end