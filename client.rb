require 'socket'
require 'digest'
require 'io/console'
require 'open-uri'
require 'openssl'
require 'base64'

MTU = 1500

public_key_file = 'public_key.pem'
$public_key = OpenSSL::PKey::RSA.new(File.read(public_key_file))
$current_user_id = "" 

loggedIn = false
while loggedIn == false do
	authServiceSock = TCPSocket.open 'localhost', 2006
	puts "1: Register"
	puts "2: Log In"
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
					puts "Registration successful!"
					puts "Please Log In..."
			end
		when /2/
			puts "USERNAME:"
			username = STDIN.gets.chomp
			puts "PASSWORD:"
			password = STDIN.noecho(&:gets).chomp

			encrypted_pw = Digest::SHA256.digest password

			message_AS = "LOGIN #{username} #{encrypted_pw}"
			encrypted_string = Base64.encode64($public_key.public_encrypt(message_AS))
			puts "#{encrypted_string}"
			authServiceSock.print("LOGIN #{encrypted_string}")
			puts "sent"
			status = authServiceSock.gets()
			case status
				when /true/
					puts "Login successful!\n"
					loggedIn = true
				when /false/
					puts "Login failed!\n"
			end
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
		File.open("ClientStore/#{path}", "a") do |file|
			while chunk = s.read(MTU)
				file.write(chunk)
			end
			puts "File received"
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
	end
	s.close
end
s.close
