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
		send_msg(msg_connect(@name))
	end

	def receive_loop

	end

	def send_msg(msg)
		msg[time] = Time.now.to_f.to_s
		json = msg.to_json
		@client.send(json, 0)
	end

	def msg_chat(body)
		{'type' => 'chat', 'body' => body}
	end

	def msg_connect(nick)
		{'type' => 'connect', 'name' => nick}
	end

	def msg_quit
		{'type' => 'quit'}
	end
	
	def terminal_config
		system("stty raw -echo")
	end

	def terminal_reset
		system("stty -raw echo")
	end

	def bye
		terminal_reset
		puts "\n\r bye \n\r"
		exit
	end

end
