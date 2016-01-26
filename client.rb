require 'socket'

MTU = 1500

loop do
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
		puts "LOAD CALLED"
		inputList = user_input.split(" ")
		inputList.shift
		path = inputList.shift
		puts "#{path}"
		File.open("ClientStore/#{path}", "r") do |file|
	 		puts "PREPARED TO SEND"
			while chunk = file.read(MTU)
	        		puts "SEND CHUNK"
			    	s.write(chunk)
	        		puts "SENT CHUNK"
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
	puts "ABOUT TO CLOSE"
	s.close
end
s.close
