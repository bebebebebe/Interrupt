# Interrupt Chat

"Realtime" interruptible chat in the terminal.

A command line chat program for multiple clients, where the idea is to give something like the experience of seeing a transcript of voice conversation. The text that clients see is updated with each keypress from a client. Each client is assigned a color, and their text appears in that color for all clients. Chat text appears on one line, with the cursor at the far right (representing "now"); text moves to the left as you type or as time passes. Clients can't delete or move the cursor left.

## To run
To run both the client and server on localhost, use one terminal window to run the server:
``
ruby server.rb
``
In another terminal window, run the client:
``
ruby client.rb
``
Run the client in a third window in the same way to chat between the two windows running the client.

If you're running the client, and the server is running elsewhere at '[server-ip-address-string]', run the client with a command line argment
``
ruby client.rb [server-ip-addres-string]
``



[Readme in progress: these are notes helpful while developing]

## Message formats:

### Sent by client:

connect:
{'type' => 'connect', 'name' => (String), 'time' => (timestamp String)}

chat:
{'type' => 'chat', 'body' => (String), 'time' => (timestamp String)}

quit:
{'type' => 'quit', 'time' => (timestamp String)}


### Sent by server:

{'type' => 'chat', 'body' => (String), 'time' => (timestamp String)}

{'type' => 'ack', 'time' => (timestamp String)}


## Behavior on wrong message types:

### Received by server:

Checks message format and sender. Ignores "wrong" messages, which are
- wrong format
- sender not in clients list, if its not a connect message
- when client sends connect message, there should be a "handshake", where the client keeps
resending the connect message until getting an acknowledgement from the server. This way
we know the server has the client in the clients list before the client starts sending chat messages.

###Received by client:

Checks message format and sender. Ignores "wrong" messages, which are:
- sender is not server
- format is wrong

## Server message representations (internal to server program)
chat message: send to all clients
{'type' => 'chat', 'msg'=> {...}}

private
{'type' => 'private', 'key'=>'..' 'msg'=> {....}}

private to "new" user (not assumed to be in client list)
{'type' => private_new, 'host'=>'..', 'port'=>.., msg=>{...}}

The values of the msg keys here are of a form in the "sent by server" section above.

## Limitations / TODO

1. The server doesn't monitor clients to see if they are still running the chat program. Currently, the server will remove clients from the list of clients to message if the client quits the program properly, i.e., by typing the quit command. However, the server won't make such an update if the client halts the chat program in another way, for instance by closing the terminal window. 

2. The client doesn't get any feedback on keypress until the server knows about it and messages all clients with an update. One possiblity is to update the chat string on the client side with newly typed data in a lighter color or grey; it would be "overwritten" in the client's ususal colour once the server message comes through.

