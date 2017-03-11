require 'socket'
require 'json'

class InterruptChat

	def initialize
		@client = UDPSocket.new
		@client.connect('localhost', 4481)

	end

	def run
		set_name
		announce
		terminal_config
		receive_loop
	end

	def set_name
		puts START_MSG
		print PROMPT
		@name = gets.chomp
	end

	def announce

	end

	def receive_loop

	end

	


end
