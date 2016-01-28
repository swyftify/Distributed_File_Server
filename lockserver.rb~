require 'socket'
require 'thread'
require 'openssl'
require 'base64'
include Socket::Constants

class LOCK
	def initialize()
		$file = { }
		@lock = Mutex.new
	end

	def setLock ( file_id )
		@lock.synchronize {
			$file[file_id] = true
		}
	end

 def releaseLock ( file_id )
		@lock.synchronize {
			$file[file_id] = false
		}
	end

	def lockedRequest ( file_id )
		@lock.synchronize {
			status = $file[file_id]
		}
	end
end

#############################################################################################

def request (input)
	inputList = input.split(" ")
	inputList.shift
	encodedData = inputList.join("")
	request = $private_key.private_decrypt(Base64.decode64(encodedData))
	requestList = request.split(" ")
	requestList.shift
	filepath = requestList.shift
	state = $lock_base.lockedRequest(filepath.to_i)
	if state.nil?
		$lock_base.setLock(filepath.to_i)
		state = $lock_base.lockedRequest(filepath.to_i)
	end

end

def release (input)
	inputList = input.split(" ")
	inputList.shift
	encodedData = inputList.join("")
	request = $private_key.private_decrypt(Base64.decode64(encodedData))
	requestList = request.split(" ")
	requestList.shift
	filepath = requestList.shift
	$lock_base.releaseLock(filepath.to_i)
end

###########################################################################################

password = 'zeroday'
$private_key = OpenSSL::PKey::RSA.new(File.read("private_key.pem"), password)
$lock_base = LOCK.new

server = TCPServer.new('localhost', 2007)
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
				if (/REQUEST \w/).match(input) != nil
					status = request(input)
					client.puts(status)
				elsif (/RELEASE \w/).match(input) != nil
					release(input)
					status = "RELEASED"
					client.puts(status)
				end
				client.close
			end
		end
	end
end

while true
end

