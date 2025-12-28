module MB
  module Util
    # Methods to help in the creation of command-line applications.
    module CliMethods
      # Sets the given OptionParser's --help message to the header help from
      # the script file.  See MB::U::FileMethods#highlight_header_comment.
      #
      # Example:
      #     # script.rb
      #     #!/usr/bin/env ruby
      #     # Some header help here
      #     #
      #     # Example for $0
      #     require 'optionparser'
      #     require 'mb-util'
      #     OptionParser.new { |p|
      #       MB::U.opt_header_help(p)
      #       p.on('-f', '--fake', 'Fake option')
      #     }.parse!
      #
      #     # Command line
      #     bundle exec ./script.rb --help
      #
      #     # Output
      #     Some header help here
      #     =====================
      #
      #     Example for script.rb
      #
      #         -f, --fake                       Fake option
      def opt_header_help(parser, filename = caller_locations(1, 1)[0].absolute_path)
        header_lines = MB::U.highlight_header_comment(filename)
        parser.banner = header_lines[0]
        header_lines[1..].each do |l|
          parser.separator(l)
        end
      end
    end
  end
end
