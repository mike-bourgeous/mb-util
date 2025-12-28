require_relative 'util/version'

require_relative 'util/console_methods'
require_relative 'util/text_methods'
require_relative 'util/platform_methods'
require_relative 'util/file_methods'
require_relative 'util/debug_methods'
require_relative 'util/cli_methods'

module MB
  # General purpose utility functions, e.g. for dealing with the display.
  #
  # Method implementations may be found in modules under util/.  No doubt
  # better categorization might be possible.
  module Util
    extend ConsoleMethods
    extend TextMethods
    extend PlatformMethods
    extend FileMethods
    extend DebugMethods
    extend CliMethods
  end

  # MB::U is a convenient shorthand for MB::Util.
  U = Util
end
