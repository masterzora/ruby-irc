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
      msg = STDIN.gets.split
      if msg[0][0] == '/'
        if msg[0][1..-1].upcase == 'JOIN'
          connection.JOIN(msg[1])
        elsif msg[0][1..-1].upcase == 'QUIT'
          connection.QUIT(msg[1..-1].join(' '))
	elsif msg[0][1..-1].upcase == 'PART'
          if msg[1][0] == '#'
            connection.PART(channel=msg[1], msg=msg[2..-1].join(' '))
          else
            connection.PART(channel=nil, msg=msg[1..-1].join(' '))
          end
        elsif msg[0][1..-1].upcase == 'MSG'
          connection.PRIVMSG(msg[2..-1].join(' '), recipient=msg[1])
	end
      else
        connection.PRIVMSG(msg.join(' '))
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
