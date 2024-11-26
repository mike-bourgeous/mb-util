module MB
  module Util
    # Methods to help with debugging code.
    module DebugMethods
      # Installs a signal handler for SIGQUIT to print a backtrace of all
      # threads.  This will be useful if you think a program or thread is stuck
      # somewhere, but you aren't sure -- you can send SIGQUIT (or press Ctrl-\
      # if running in a terminal) to print a stack trace without killing the
      # program.
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
          Thread.list.each do |t|
            MB::U.headline "Thread #{MB::U.highlight(t)}#{t == Thread.current ? ' (current thread)' : ''}"
            puts MB::U.color_trace(t.backtrace)
          end
        end
      end
    end
  end
end
