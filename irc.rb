#!/usr/bin/env ruby

require_relative 'ircconnection'

connection = IrcConnection.new('irc.esper.net', 6667)
connection.USER('sauron', 'Sauron')
connection.NICK('sauron')
#i = 0
while 1==1
#while i < 10
  ready = select([STDIN, connection.socket], nil, nil)[0]
  for s in ready
    if s == STDIN
      msg = STDIN.gets
      if msg[0] == '/'
        if msg[1..5] == 'JOIN '
          connection.JOIN(msg[6..-1])
	end
      else
        connection.PRIVMSG(msg)
      end
    elsif s == connection.socket
      msg = connection.read
      puts msg
      if msg[0..5] == 'PING :'
	print "PONG :", msg[6..-1], "\n"
        connection.PONG(msg[6..-1])
      end
    end
  end
#  i += 1
end
#connection.JOIN('#mztestbed')
#connection.QUIT('So long and thanks for all the fish')
