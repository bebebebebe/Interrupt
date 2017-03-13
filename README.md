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
resending the connect message until getting an acknowledgement from the client. This way
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



