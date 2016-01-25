require 'socket'
 require 'benchmark'
 SIZE = 1024 * 1024 * 10
 server =  TCPServer.new("127.0.0.1", 12345)
 puts "Server listening..."            
 client = server.accept       
 time = Benchmark.realtime do
   File.open('c:/file.mp3', 'w') do |file|
     while chunk = client.read(SIZE)
       file.write(chunk)
     end
 end
end