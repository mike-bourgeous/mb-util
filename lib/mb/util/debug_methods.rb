module MB
  module Util
    # Methods to help with debugging code.
    module DebugMethods
      # Prints a colorized backtrace for each thread.
      #
      # See #sigquit_backtrace
      def all_threads_backtrace
        thread_count = Thread.list.count
        Thread.list.each.with_index do |t, idx|
          MB::U.headline "Thread #{idx + 1}/#{thread_count}: #{MB::U.highlight(t)}#{t == Thread.current ? ' (current thread)' : ''}"
          puts MB::U.color_trace(t.backtrace)
        end
      end

      # Installs a signal handler for SIGQUIT to print a backtrace of all
      # threads.  This will be useful if you think a program or thread is stuck
      # somewhere, but you aren't sure -- you can send SIGQUIT (or press Ctrl-\
      # if running in a terminal) to print a stack trace without killing the
      # program.
      #
      # If a block is given, then the signal handler will yield to the block
      # after printing each trace.  This can be used to change some variables
      # or print additional information when SIGQUIT is pressed.  Note that
      # this yield happens within the signal handler context, meaning you
      # cannot acquire locks, run a Pry console, etc.  If you need to do these
      # things, just set a flag that gets read by your main thread, and have
      # the main thread take action.
      #
      # Run this function once as your program starts to install the SIGQUIT
      # handler.
      #
      # Credit where due: this is inspired by Java's SIGQUIT behavior.
      def sigquit_backtrace
        # pre-load requirements outside of trap context (these methods may call require)
        MB::U.highlight(nil)
        MB::U.color_trace([])

        trap :QUIT do
          all_threads_backtrace
          yield if block_given?
        end
      end
    end
  end
end
