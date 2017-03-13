require 'socket'
require 'json'

class InterruptClient

	START_MSG = 'Welcome! What is your name?'
	PROMPT = '> '
	MAX_MSG_LENGTH = 1024 # max length of incoming message read
	HANDSHAKE_WAIT = 2 # number of seconds to wait for ack from server before resending


	def initialize(server_host, server_port)
		@server_host = server_host
		@server_port = server_port

		@client = UDPSocket.new
		@client.connect(@server_host, @server_port)
	end

	def run
		set_name
		handshake
		#terminal_config
		receive_loop
	end

	def set_name
		puts START_MSG
		print PROMPT
		@name = gets.chomp
	end

	def handshake
		ackd = false
		while not ackd
			send_msg(msg_connect(@name))
			incoming = IO.select([@client], nil, nil, HANDSHAKE_WAIT)
			if ((not incoming.nil?) && ack?)
				ackd = true
			end
		end
	end

	def ack?
		data, sender = @client.recvfrom(MAX_MSG_LENGTH)
		msg = parse_msg(data, sender)
		return false if msg.nil?

		msg['type'] == 'ack'
	end

	def receive_loop
		loop do
			to_read = IO.select([@client, STDIN]) # check what's ready to read: socket, or terminal input
			to_read[0].each { |ios|

				if ios == @client
					msg, sender = ios.recvfrom(MAX_MSG_LENGTH)
					p msg
					bye
				end
			}
		end
	end

	# return parsed msg if correct format and comes from Interrupt server
	# return nil otherwise
	def parse_msg(data, sender)
		return nil if not is_server?(sender)

		begin
			msg = JSON.parse(data)
			msg = check_fields(msg)
		rescue
			nil
		end
	end

	def is_server?(sender)
		port = sender[1]
		host = sender[2]

		(port == @server_port) && (host == @server_host)
	end

	# return nil if fields wrong, otherwise return msg
	def check_fields(msg)
		basic_fields = (msg.has_key?('type') && msg.has_key?('time'))
		return nil if not basic_fields

		case msg['type']
		when 'chat'
			msg if msg.has_key?('body')
		when 'ack'
			msg
		else
			nil
		end
	end


	def send_msg(msg)
		msg['time'] = Time.now.to_f.to_s
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



SERVER_HOST = '127.0.0.1'
SERVER_PORT = 4481

client = InterruptClient.new(SERVER_HOST, SERVER_PORT)
client.run
