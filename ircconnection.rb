require "socket"

class IrcConnection
  def initialize (hostname, port)
    CONNECT(hostname, port)
  end

  def CONNECT (hostname, port)
    @hostname = hostname
    @port = port
    @socket = TCPSocket.open(@hostname, @port)
    @channels = []
  end

  def USER (user, real_name)
    @user = user
    @real_name = real_name
    @socket.puts("USER #{user} 0 * :#{real_name}")
  end

  def NICK (nickname)
    @nickname = nickname
    @socket.puts("NICK #{nickname}")
  end

  def PONG(ping_id)
    @socket.puts("PONG :#{ping_id}")
  end

  def QUIT(message)
    @socket.puts("QUIT :#{message}")
  end

  def JOIN(channel)
    channel = channel.chomp
    if not @channels.include?(channel)
      @socket.puts("JOIN #{channel}")
      @channels.push(channel)
    end
  end

  def PRIVMSG(msg, recipient=nil)
    if recipient.nil?
      recipient = @channels[0]  # TODO: make this not stupid for multiple channels
    end
    puts ("PRIVMSG #{recipient} :#{msg}")
    @socket.puts("PRIVMSG #{recipient} :#{msg}")
  end

  def read
    @socket.gets("\n")
  end

  def socket
    @socket
  end
end
