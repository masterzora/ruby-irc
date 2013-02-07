#!/usr/bin/env ruby

require_relative 'ircconnection'
require 'ncurses'

class IrcWindow
  def initialize
    @output_field = Ncurses::Form::FIELD.new(Ncurses.LINES-2, Ncurses.COLS, 1, 0, 0, 0)
    @input_field = Ncurses::Form::FIELD.new(1, Ncurses.COLS, Ncurses.LINES-1, 0, 0, 0)
    @output_field.field_opts_off(Ncurses::Form::O_AUTOSKIP)
    @output_field.field_opts_off(Ncurses::Form::O_STATIC)
    @output_field.field_opts_off(Ncurses::Form::O_ACTIVE)
    @input_field.field_opts_off(Ncurses::Form::O_AUTOSKIP)
    @input_field.field_opts_off(Ncurses::Form::O_STATIC)
    @form = Ncurses::Form::FORM.new([@output_field, @input_field])
    rows = Array.new
    cols = Array.new
    @form.scale_form(rows, cols)
    form_win = Ncurses::WINDOW.new(rows[0], cols[0], 0, 0)
    form_win.keypad(true)
    @form.set_form_win(form_win)
    @form.post_form
    @output_field.set_field_buffer(0, "Test message")
    @outputs = Array.new
    @inputs = Array.new
    form_win.wrefresh
  end

  def output(msg)
    @outputs.push(msg)
    output = ''
    if @outputs.size < Ncurses.LINES - 2
      @outputs.each do |line|
        output << line << ' ' * (Ncurses.COLS - (line.size % Ncurses.COLS))
      end
    else
      @outputs[-10..-1].each do |line|
        output << line << ' ' * (Ncurses.COLS - (line.size % Ncurses.COLS))
      end
    end
    @output_field.set_field_buffer(0, output)
  end

  def input(ch)
    case ch
    when Ncurses::KEY_BACKSPACE, 127  # worry about working now, portability later
      @form.form_driver(Ncurses::Form::REQ_DEL_PREV)
    when Ncurses::KEY_ENTER, ?\n.ord, ?\r.ord
      @form.form_driver(Ncurses::Form::REQ_CLR_FIELD)
    when Ncurses::KEY_LEFT
      @form.form_driver(Ncurses::Form::REQ_PREV_CHAR)
    when Ncurses::KEY_RIGHT
      @form.form_driver(Ncurses::Form::REQ_NEXT_CHAR)
    else
      @form.form_driver(ch)
    end
  end

  def refresh
    @form.form_win.wrefresh
  end

  def clean
    @form.unpost_form
    @form.free_form
    @output_field.free_field
    @input_field.free_field
  end

  def output_buffer
    @output_field.field_buffer(0)
  end
end

windows = {}

Signal.trap(:INT) do
  windows.each{|key, value| value.clean}
  Ncurses.endwin()
  exit
end

Ncurses.initscr()
Ncurses.keypad(Ncurses.stdscr, true)
Ncurses.nonl()
Ncurses.cbreak()
Ncurses.noecho()

stdscr = Ncurses.stdscr

connection = IrcConnection.new('irc.esper.net', 6667)
connection.USER('sauron', 'Sauron')
connection.NICK('sauron')

stdin_msg = ''

windows['default'] = IrcWindow.new

while true
  ready = select([STDIN, connection.socket], nil, nil)[0]
  for s in ready
    if s == STDIN
      new_char = Ncurses.getch()

      windows['default'].input(new_char)
      
      case new_char
      when Ncurses::KEY_BACKSPACE, 127  
        stdin_msg.chop!
        next
      when Ncurses::KEY_ENTER, ?\n.ord, ?\r.ord
      when Ncurses::KEY_LEFT, Ncurses::KEY_RIGHT, Ncurses::KEY_UP, Ncurses::KEY_DOWN
        next
      else
        stdin_msg << new_char
        next
      end

      msg = stdin_msg.split
      stdin_msg = ''

      if msg.size == 0
        next
      end

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
      if msg.nil?
        next
      end
      msgs = msg.split("\n")
      msgs.each do |msg|
        msg.gsub!(/\s/, ' ')
        windows['default'].output(msg)
      end
      if msg[0..5] == 'PING :'
        connection.PONG(msg[6..-1])
      end
    end
  end
  Ncurses.refresh()
  windows['default'].refresh
end

Ncurses.endwin()
