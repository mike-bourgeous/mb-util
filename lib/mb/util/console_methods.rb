require 'io/console'

module MB
  module Util
    # Methods related to the terminal/console, such as finding the size of a
    # terminal window.
    #
    # MB::Util extends itself with this module, so use these methods via
    # MB::Util.
    module ConsoleMethods
      # The width of the terminal window, defaulting to 80 if the width can't
      # be determined.
      def width
        IO.console&.winsize&.last || ENV['COLUMNS']&.to_i || 80
      end

      # The height of the terminal window, defaulting to 25 if the height can't
      # be determined.
      def height
        IO.console&.winsize&.first || ENV['ROWS']&.to_i || 25
      end
    end
  end
end
