
require 'openssl'
require 'base64'
require 'socket'
require 'thread'
include Socket::Constants

class DIRECTORY
	def initialize()
		$file = { }
		$address = { }
		$port = { }
		@lock = Mutex.new
	end
	
	def getFileLocation ( file_id )
		@lock.synchronize {
			file = $file[file_id]
		}
	end

	def getAddress ( file_id )
		@lock.synchronize {
			address = $address[file_id]
		}
	end

	def getPort ( file_id )
		@lock.synchronize {
			port = $port[file_id]
		}
	end

	def setFileLocation (address, port, file, file_id)
		@lock.synchronize {
			$file[file_id] = file	
			$address[file_id] = address
			$port[file_id] = port
		}
	end
end

##########################################################################################

def addEntry(input)
	inputList = input.split(" ")
	inputList.shift
	encodedData = inputList.join("")
	request = $private_key.private_decrypt(Base64.decode64(encodedData))
	puts "#{request}"
	decodedList = request.split(" ")
	decodedList.shift				# remove add
	decodedList.shift
	serverIP = decodedList.shift
	decodedList.shift
	serverPort = decodedList.shift
	decodedList.shift
	filepath = decodedList.shift
	puts "#{clientIP}	#{clientPort}	#{filepath}"
	$directoryBase.setFileLocation(serverIP, serverPort, filepath, filepath.to_i)
end

def getEntry(input)
	inputList = input.split(" ")
	inputList.shift
	encodedData = inputList.join("")
	request = $private_key.private_decrypt(Base64.decode64(encodedData))
	puts "#{request}"
	filepath = request.split(" ")
	filepath.shift		
	address = $directoryBase.getAddress( filepath.to_i )
	port = $directoryBase.getPort( filepath.to_i )
	file = $directoryBase.getFileLocation( filepath.to_i ) 
	puts "#{file}, #{address}, #{port}"
end

def get (encrypted_request)
	remove_GET = encrypted_request.split("GET")[1].strip()
	request = $private_key.private_decrypt(Base64.decode64(remove_GET))
	puts "#{request}"
	parse = request.split("GET")[1].strip()
	file = $directoryBase.getFileLocation( parse.to_i ) 
	address = $directoryBase.getAddress( parse.to_i )
	port = $directoryBase.getPort( parse.to_i )
	puts "#{file}, #{address}, #{port}"
end

###########################################################################################

password = 'zeroday'
$private_key = OpenSSL::PKey::RSA.new(File.read("private_key.pem"), password)
$directoryBase = DIRECTORY.new

server = TCPServer.new('localhost', 2008)
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
					input << message
				end
				if (/ADD \w/).match(input) != nil
					addEntry(input)
				elsif (/GET \w/).match(input) != nil
					getEntry(input)
				end
				client.close
			end
		end
	end
end

while true
end