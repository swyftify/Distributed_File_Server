require 'socket'
require 'thread'
require 'openssl'
require 'base64'

class AUTH_BASE
	def initialize()
		$username = { }
		$password = { }
		$login = { } 
		@lock = Mutex.new
	end

	def registerUser ( join_id, username, password )
		@lock.synchronize {
			$username[join_id] = username
			$password[join_id] = password
			puts "USER: #{username} REGISTERED SESSION ID: #{join_id}"
			$login[join_id] = false
		}
	end

	def login ( join_id, username, password )
		@lock.synchronize {
			check_username = $username[join_id]
			check_password = $password[join_id]
			if ((check_username.eql?(username)) && (check_password.eql?(password)))
				puts "USER: #{username} LOGGED IN WITH SESSION ID: #{join_id}"
				$login[join_id] = true
			end
			status = $login[join_id]
		}
	end

	def logout ( join_id, username )
		@lock.synchronize {
			check_username = $username[join_id]
			if (check_username == username)
				puts "USER: #{username} LOGGED OUT WITH SESSION ID: #{join_id}"
				$login[join_id] = false
			end
		}
	end
end

def register( input )
	inputList = input.split(" ")
	inputList.shift
	encodedData = inputList.join("")
	request = $private_key.private_decrypt(Base64.decode64(encodedData))	# decrypted whole request 
	requestList = request.split(" ")
	requestList.shift
	username = requestList.shift
	password = requestList.shift
	joinID = username.hash
	$authbase.registerUser(joinID, username, password)
	state = $authbase.login(joinID, username,password)
	$authbase.logout(joinID,username)
end

def login(input)
	inputList = input.split(" ")
	inputList.shift
	encodedData = inputList.join("")
	request = $private_key.private_decrypt(Base64.decode64(encodedData))	# decrypted whole request 
	requestList = request.split(" ")
	requestList.shift
	username = requestList.shift
	password = requestList.shift
	joinID = username.hash
	state = $authbase.login(joinID, username,password)
end

def logout(input)
	inputList = input.split(" ")
	inputList.shift
	encodedData = inputList.join("")
	request = $private_key.private_decrypt(Base64.decode64(encodedData))	# decrypted whole request 
	requestList = request.split(" ")
	requestList.shift
	username = requestList.shift
	joinID = username.hash
	state = $authbase.logout(joinID, username)
end

service_kill = false
$public_key = OpenSSL::PKey::RSA.new(File.read("public_key.pem"))
password = 'zeroday'
$private_key = OpenSSL::PKey::RSA.new(File.read("private_key.pem"), password)
$authbase = AUTH_BASE.new
server = TCPServer.new('localhost', 2006)
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
				input = ""
				while !input.include? "==" do
		  			message = client.gets()
		  			if message == "KILL_SERVICE"
		  				input = message
		  				break
		  			end
					input << message
				end
				if (/REGISTER \w/).match(input) != nil
					state = register(input)
					client.puts(state)
				elsif (/LOGIN \w/).match(input) != nil
					state = login(input)
					client.puts(state)
				elsif (/LOGOUT \w/).match(input) != nil
					state = logout(input)
					client.puts(state)
				elsif input.include? "KILL_SERVICE"
					service_kill = true
				end
				client.close
			end
		end
	end
end

while !service_kill
end