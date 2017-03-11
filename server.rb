require 'socket'
require 'json'

class InterruptChat
	
	def initialize(host, port)
		@server = UDPSocket.new
		@server.bind(host, port)

		@clients = {}
		@chat_update = nil # hash or nil
		@outbox = [] # array of json strings
	end

	def run
		data, sender = @server.recvfrom(1024)
		handle_incoming(data, sender)
		handle_outgoing
	end

	def handle_incoming(data, sender)
		msg = parse_msg(data)
		return if msg == nil

		key = get_key(sender)


	end

	def handle_outgoing

	end


	def get_key(sender)
		sender[1] + sender[2].to_s # host + port is unique per client
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
		basic_fields? = msg.has_key? 'type' && msg.has_key? 'time'
		return nil if not basic_fields?

		case msg['type']
		when 'connect'
			has_keys = msg.has_key? 'name'
		when 'chat'
			has_keys = msg.has_key? 'body'
		when 'quit'
			
		else
			return nil
		end

		return msg
	end

end

