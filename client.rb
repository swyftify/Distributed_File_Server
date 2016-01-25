require 'socket'

SIZE = 1024 * 1024 * 10

loop do
	puts "Awaiting input"
	user_input = gets.chomp  
	s = TCPSocket.open 'localhost', 2005
	s.puts(user_input)
	path = user_input.split(" ")
	File.open("ClientStore/#{path[1]}", 'w') do |file|
		puts "Writing file"
    	while chunk = s.read(SIZE)
    		file.write(chunk)
    	end
    	puts "Received"
    	file.close
    end
	s.close
end
s.close
