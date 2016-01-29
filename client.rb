require 'socket'
require 'digest'
require 'io/console'
require 'open-uri'
require 'openssl'
require 'base64'

MTU = 1500

public_key_file = 'public_key.pem'
$public_key = OpenSSL::PKey::RSA.new(File.read(public_key_file))

loggedIn = false
loop do 
	while loggedIn == false do
		authServiceSock = TCPSocket.open 'localhost', 2006
		puts "1: Register"
		puts "2: Log In"
		puts "3: Exit"
		inputChoice = STDIN.gets.chomp
		case inputChoice
			when /1/
				puts "USERNAME: "
				username = STDIN.gets.chomp
				puts "PASSWORD:"
				password = STDIN.noecho(&:gets).chomp
				encrypted_pw = Digest::SHA256.digest password	
				message_AS = "REGISTER #{username} #{encrypted_pw}"
				encrypted_string = Base64.encode64($public_key.public_encrypt(message_AS))
				authServiceSock.print("REGISTER #{encrypted_string}")
				status = authServiceSock.gets()
				case status
					when /false/
						puts "Registration successful!\nPlease Log In..."
				end
			when /2/
				puts "USERNAME:"
				username = STDIN.gets.chomp
				$encryptedClientNameSession = Base64.encode64(username)
				puts "PASSWORD:"
				password = STDIN.noecho(&:gets).chomp
				encrypted_pw = Digest::SHA256.digest password
				message_AS = "LOGIN #{username} #{encrypted_pw}"
				encrypted_string = Base64.encode64($public_key.public_encrypt(message_AS))
				authServiceSock.print("LOGIN #{encrypted_string}")
				status = authServiceSock.gets()
				case status
					when /true/
						puts "Login successful!"
						loggedIn = true
					when /false/
						puts "Login failed!"
				end
			when /3/
				puts "Closing session"
				authServiceSock.close
				puts "See you soon..."
				exit(true)
		end
	end

	while loggedIn == true do
		puts "Awaiting input"
		user_input = gets.chomp  
		s = TCPSocket.open 'localhost', 2005
		s.puts(user_input)		
		if(/READ \w/).match(user_input) != nil
			inputList = user_input.split(" ")
			inputList.shift
			path = inputList.shift
			avstate = s.gets()
			if avstate == false or avstate.include? "false"
				puts "No file or directory"
			else
				if File.exist?("ClientStore/#{path}") == true
					File.delete("ClientStore/#{path}")
					File.open("ClientStore/#{path}", "a") do |file|
						file.write(avstate)
						while chunk = s.read(MTU)
							file.write(chunk)
						end
						puts "File received"
					end
				elsif File.exist?("ClientStore/#{path}") == false
					File.open("ClientStore/#{path}", "a") do |file|
						file.write(avstate)
						while chunk = s.read(MTU)
							file.write(chunk)
						end
						puts "File received"
					end
				end
			
			end
		elsif(/LOAD \w/).match(user_input) != nil
			inputList = user_input.split(" ")
			inputList.shift
			path = inputList.shift
			File.open("ClientStore/#{path}", "r") do |file|
				while chunk = file.read(MTU)
				    	s.write(chunk)
		    		end
				puts "File sent to server"
			end
		elsif (/WRITE \w/).match(user_input) != nil
			inputList = user_input.split(" ")
			inputList.shift
			path = inputList.shift
			textToWrite = inputList.join(" ")
			if File.exist?("ClientStore/#{path}") == false
				file = File.new("ClientStore/#{path}", "a")
				file.write("#{textToWrite}\n")
				file.close
			elsif File.exist?("ClientStore/#{path}") == true	
				file = File.open("ClientStore/#{path}", "a")
				file.write("#{textToWrite}\n")
				file.close
			end
		elsif user_input.include? "LOGOUT" or user_input.include? "EXIT"
			authServiceSock = TCPSocket.open 'localhost', 2006
			decodedSessionName = Base64.decode64($encryptedClientNameSession)
			msg = "LOGOUT " + "#{decodedSessionName}"
			encryptedLogout = Base64.encode64($public_key.public_encrypt(user_input))
			authServiceSock.print("LOGOUT #{encryptedLogout}")
			status = authServiceSock.gets()
			case status
				when /false/
					puts "LOGGED OUT SUCCESSFUL"
					loggedIn = false
				when /true/
					puts "ERROR: Something went wrong during logout"
			end
			if user_input.include? "EXIT"
				puts "Closing session"
				s.close
				authServiceSock.close
				puts "See you soon..."
				exit(true)
			end
		end
		authServiceSock.close
		s.close
	end
end
s.close
