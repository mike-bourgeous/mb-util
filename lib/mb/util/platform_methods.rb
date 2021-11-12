module MB
  module Util
    # Methods related to the operating system, such as default buffer sizes for
    # pipes.
    #
    # MB::Util extends itself with this module, so use these methods via
    # MB::Util.
    module PlatformMethods
      # Returns the current time from the system's monotonically increasing
      # clock.  A shorthand for Process.clock_gettime(Process::CLOCK_MONOTONIC).
      def clock_now
        Process.clock_gettime(Process::CLOCK_MONOTONIC)
      end

      # On Linux, changes the kernel's buffer size for the given pipe.  This
      # should cause the pipe to exert more backpressure on reading or writing.
      # See F_SETPIPE_SZ in the fcntl(2) and pipe(7) manual pages for more
      # details.
      #
      # Returns the actual size set by the kernel on success.
      #
      # Raises SystemCallError, Errno::EPERM (if the size is larger than the
      # fs.pipe-max-size sysctl), or possibly IOError on failure.  Or may
      # return -1 on error, e.g. on TruffleRuby.
      def pipe_size(io, size)
        if RUBY_PLATFORM =~ /linux/
          @max_pipe ||= max_pipe_size
          size = @max_pipe if size > @max_pipe

          # TODO: Use the value from Fcntl when a stable Ruby release provides
          # F_SETPIPE_SZ.  Until then, hard-code the Linux-specific fcntl ID of
          # 1031.
          return io.fcntl(1031, size)
        end
      end

      # On Linux, retrieves the largest pipe size, in bytes, allowed for
      # unprivileged users.  Returns 4096 as a default on unsupported
      # platforms, or if there was an error reading the max size.
      def max_pipe_size
        case RUBY_PLATFORM
        when /linux/
          size = File.read('/proc/sys/fs/pipe-max-size').strip.to_i rescue 4096
          size = 4096 if size <= 0
          size

        else
          4096
        end
      end
    end
  end
end
