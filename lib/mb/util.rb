require 'io/console'

require_relative 'util/version'

module MB
  # General purpose utility functions, e.g. for dealing with the display.
  #
  # Some of these functions will use Pry or CodeRay if available.
  #
  # Most things in here should eventually be moved elsewhere as better
  # abstractions are discovered.
  module Util
    # The width of the terminal window, defaulting to 80 if the width can't
    # be determined.
    def self.width
      IO.console.winsize&.last || ENV['COLUMNS']&.to_i || 80
    end

    # The height of the terminal window, defaulting to 25 if the height can't
    # be determined.
    def self.height
      IO.console.winsize&.first || ENV['ROWS']&.to_i || 25
    end

    # Wraps the given text for the current terminal width, or 80 columns if
    # the terminal width is unknown.  Returns the text unmodified if WordWrap
    # is unavailable.
    def self.wrap(text, width: self.width)
      require 'word_wrap'
      WordWrap.ww(text, width - 1, true) # FIXME: doesn't ignore ANSI escapes
    rescue LoadError
      text
    end

    # Returns a copy of the String with ANSI-style escape sequences removed.
    def self.remove_ansi(str)
      str.gsub(/\e\[[^A-Za-z]*[A-Za-z]/, '')
    end

    # Returns a String with a syntax highlighted form of the given +object+,
    # using Pry's ColorPrinter.  If the ColorPrinter is not available,
    # CodeRay will be used, and failing that, the string will be bolded.
    def self.highlight(object, columns: nil)
      require 'pry'
      Pry::ColorPrinter.pp(object, '', columns || width)
    rescue LoadError
      begin
        syntax(object.inspect)
      rescue LoadError
        "\e[1m#{object.inspect}\e[0m"
      end
    end

    # Returns a String with the given Ruby code highlighted by CodeRay.  If
    # CodeRay is not available, then a simple character highlight will be
    # applied.
    def self.syntax(code)
      require 'coderay'
      CodeRay.scan(code.to_s, :ruby).terminal
    rescue LoadError
      code.to_s
        .gsub(/[0-9]+/, "\e[34m\\&\e[37m")
        .gsub(/[[:upper:]][[:alpha:]_]+/, "\e[32m\\&\e[37m")
        .gsub(/[{}=<>]+/, "\e[33m\\&\e[37m")
        .gsub(/["'`]+/, "\e[35m\\&\e[37m")
        .gsub(/[:,]+/, "\e[36m\\&\e[37m")
    end

    # On Linux, changes the kernel's buffer size for the given pipe.  This
    # should cause the pipe to exert more backpressure on reading or writing.
    # See F_SETPIPE_SZ in the fcntl(2) and pipe(7) manual pages for more
    # details.
    #
    # Returns the actual size set by the kernel on success.
    #
    # Raises SystemCallError, Errno::EPERM (if the size is larger than the
    # fs.pipe-max-size sysctl), or possibly IOError on failure.
    def self.pipe_size(io, size)
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
    def self.max_pipe_size
      case RUBY_PLATFORM
      when /linux/
        size = File.read('/proc/sys/fs/pipe-max-size').strip.to_i rescue nil
        size = 4096 if size <= 0 || size.nil?
        size

      else
        4096
      end
    end
  end

  U = Util
end
