#!/usr/bin/env ruby
# Example program for the SIGQUIT backtrace handler.
# Starts a few threads, waits a bit, sends SIGQUIT to the process, then exits,
# to show what the output of MB::U.sigquit_backtrace looks like.

require 'bundler/setup'

require 'mb/util'

if ARGV.include?('--yield')
  MB::U.sigquit_backtrace(headline: 'With block') { puts 'Yielded!' }
else
  MB::U.sigquit_backtrace
end

def f1
  f2
end

def f2
  f3
end

def f3
  sleep
end

tlist = Array.new(5) { |i|
  t = Thread.new {
    Thread.current.name = "Thread #{i + 1}"
    case i
    when 0
      f1

    when 1
      f2

    when 2
      f3

    else
      sleep
    end
  }
}

Thread.current.name = 'Main process'

MB::U.headline 'SIGQUIT backtrace demo'

puts 'Waiting for all threads to be sleeping'
loop do
  break if tlist.all? { |t| t == Thread.current || t.status == 'sleep' }
  sleep 0.1
end

puts 'Sending SIGQUIT'
Process.kill(:QUIT, Process.pid)

puts 'Shutting down'

tlist.map(&:wakeup)
tlist.map(&:join)
