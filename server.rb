require 'socket'
require 'json'

class InterruptServer

	CHAT_LENGTH = 45 # length of chat text user can see at one time
	TICK_LENGTH = 0.75 # how many seconds to wait before 'moving chat text left'
	MAX_MSG_LENGTH = 1024 # max length of incoming message read
	
	def initialize(host, port, num_colors=5)
		@server = UDPSocket.new
		@server.bind(host, port)

		@clients = {}
		@colors_available = [*0..num_colors-1]

		@chat_array = Array.new(CHAT_LENGTH, [' ', nil]) # each element is [character, color]
		@outbox = [] # array of messages, as hashes with sender info
	end

	def run
		loop do
			incoming = IO.select([@server], nil, nil, TICK_LENGTH)
			if incoming.nil?
				tick
			else
				data, sender = @server.recvfrom(MAX_MSG_LENGTH)
				handle_incoming(data, sender)
			end
			handle_outbox
		end
	end

	def tick
		if @chat_array != ' ' * CHAT_LENGTH
			update_chat_text(' ', nil)
		end
	end

	def handle_incoming(data, sender)
		msg = parse_msg(data)
		return if msg == nil

		key, host, port = sender_info(sender)

		case msg['type']
		when 'connect'
			add_client(key, host, port, msg['name'], msg['time'])
			assign_color(key)
			ack_client(host, port)

		when 'quit'
			delete_client(key)

		when 'chat'
			if @clients.has_key? key and new_msg?(key, msg['time'])
				color = @clients[key]['color']
				update_time(key, msg['time'])
				update_chat_text(msg['body'], color)

			end
		end
	end

	def assign_color(client_key)
		return if @colors_available.empty?

		@clients[client_key]['color'] = @colors_available.shift
	end

	def handle_outbox
		while not @outbox.empty?
			msg = @outbox.shift

			case msg['type']
			when 'chat'
				@clients.each{ |key, client|
					host = client['host']
					port = client['port']
					send_msg(msg['msg'], host, port)
				}

			when 'private_new'
				send_msg(msg['msg'], msg['host'], msg['port'])

			when 'private'
				if @clients.has_key?(msg['key'])
					client = @clients[key]
					send_msg(msg['msg'], client['host'], client['port'])
				end

			end
		end
	end


	def sender_info(sender)
		port = sender[1]
		host = sender[2]
		key = port.to_s + host # host + port is unique per client

		[key, host, port]
	end

	# parse to json, and ensure formatted correctly
	# return nil if not
	def parse_msg(data)
		begin
			msg = JSON.parse(data)
			msg = check_fields(msg)
		rescue
			nil
		end
	end

	# return nil if fields wrong, otherwise return msg
	def check_fields(msg)
		basic_fields = (msg.has_key?('type') && msg.has_key?('time'))
		return nil if not basic_fields

		case msg['type']
		when 'connect'
			msg if msg.has_key?('name')
		when 'chat'
			msg if msg.has_key?('body')
		when 'quit'
			msg
		else
			nil
		end
	end

	def add_client(key, host, port, nickname, time)
		@clients[key] = {
			'key' => key,
			'name' => nickname,
			'time' => time,
			'host' => host,
			'port' => port,
			'color' => nil
		}
	end

	def delete_client(key)
		if (@clients.has_key?(key) && @clients[key]['color'])
			@colors_available << @clients[key]['color']
		end

		@clients.delete(key)
	end

	def update_time(key, time)
		@clients[key]['time'] = time
	end

	def new_msg?(key, time)
		@clients[key]['time'] <= time
	end

	def update_chat_text(chr, color=nil)
		@chat_array << [chr, color]
		@chat_array.shift

		msg = {
			'type' => 'chat',
			'msg' => {
				'type' => 'chat',
				'body' => @chat_array
			}
		}

		@outbox << msg
	end

	def ack_client(host, port)
		msg = {
			'type' => 'private_new',
			'host' => host,
			'port' => port,
			'msg' => {'type' => 'ack'}
		}

		@outbox << msg
	end

	def send_msg(msg, host, port)
		msg['time'] = Time.now.to_f.to_s

		json = msg.to_json
		@server.send(json, 0, host, port)
	end
end

SERVER_HOST = 'localhost'
SERVER_PORT = 4481

server = InterruptServer.new(SERVER_HOST, SERVER_PORT)
server.run
