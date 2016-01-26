require 'socket'

MTU = 1500

loop do
	puts "Awaiting input"
	user_input = gets.chomp  
	s = TCPSocket.open 'localhost', 2005
	s.puts(user_input)
	puts s.gets
	sizeReceived = false
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
	end
	s.close
end
s.close
