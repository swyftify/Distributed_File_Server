require 'socket'

loop do
	puts "Awaiting input"
	user_input = gets.chomp  
	s = TCPSocket.open 'localhost', 2005
	s.puts(user_input)
	puts s.gets
	if(/READ \w/).match(user_input) != nil
		while line = s.gets   
 			puts line.chop     
		end
	end
	s.close
end
s.close
