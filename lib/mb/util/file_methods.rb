module MB
  module Util
    # Methods useful for working with files, such as interactive prompts to
    # prevent accidentally overwriting files.
    #
    # MB::Util extends itself with this module, so use these methods via
    # MB::Util.
    module FileMethods
      class FileExistsError < RuntimeError
        def initialize(filename)
          super("File #{filename} already exists")
        end
      end

      # Checks if +filename+ already exists.
      #
      # If the file exists and +:prompt+ is true, then the user is asked
      # whether to overwrite the file.
      #
      # If the file exists and +:prompt+ is false, or if the user chooses not
      # to overwrite the file, a FileExistsError is raised.
      #
      # Does nothing if the file does not exist.
      def prevent_overwrite(filename, prompt:)
        return unless File.exist?(filename)

        if prompt
          STDOUT.write("\e[1;33m#{filename}\e[22m already exists.  Overwrite it?\e[0m")

          if prompt_yes_no
            STDOUT.write("\e[36mOverwriting \e[1m#{filename}\e[22m.\e[0m\n")
            return
          end
        end

        STDOUT.write("\e[31mNot overwriting existing file \e[1m#{filename}.\e[0m\n")
        raise FileExistsError, filename
      end

      # Prevents accidentally overwriting any files matching the wildcard
      # +glob+ (see Dir#glob).
      #
      # If +:prompt+ is true and any files match the +glob+, the user will be
      # asked whether to overwrite the existing files.  If the user chooses to
      # overwrite and +:delete+ is true (the default), the existing files will
      # be deleted before returning.
      #
      # If +:prompt+ is false and files match the +glob+, or if the user
      # chooses not to overwrite files, then a FileExistsError will be raised.
      #
      # Does nothing if no files match the +glob+.
      def prevent_mass_overwrite(glob, prompt:, delete: true)
        existing_files = Dir[glob].sort
        return if existing_files.empty?

        if prompt
          STDOUT.write("\e[1;33m#{existing_files.length}\e[22m file(s) (such as \e[1m#{existing_files.first}\e[22m) already exist.  Delete them and proceed?\e[0m")

          if prompt_yes_no
            if delete
              STDOUT.write("\e[33mDeleting \e[1m#{existing_files.length}\e[22m files\e[0;36m and continuing.\e[0m\n")

              existing_files.each do |f|
                File.unlink(f)
              end

            else
              STDOUT.write("\e[36mContinuing.\e[0m\n")
            end

            return
          end
        end

        STDOUT.write("\e[31mNot overwriting \e[1m#{existing_files.count}\e[22m existing files.\e[0m\n")
        raise FileExistsError, existing_files.first
      end

      # Loops printing a Yes/No prompt and asking for user input until the
      # users answers either yes or no.  Returns true if they answered starting
      # with a Y, false if they answered starting with N.
      #
      # The +:color+ parameter may specify a different ANSI color for the
      # \e[...m sequence.  For example, "34" for dark blue, "1;34" for bold
      # blue.  See https://en.wikipedia.org/wiki/ANSI_escape_code#Colors
      def prompt_yes_no(color: '1;33')
        loop do
          STDOUT.write(" \e[#{color}m[Y / N]\e[0m ")
          STDOUT.flush

          reply = STDIN.readline

          case reply.downcase[0]
          when 'y'
            return true

          when 'n'
            return false
          end
        end
      end

      # Returns an Array containing the initial lines from the file that match
      # the +:comment_regexp+, removing the first instance of +:comment_regexp+
      # from each line, and skipping an initial shebang line ("#!...") if
      # present.
      def read_header_comment(filename = caller_locations(1,1)[0].absolute_path, comment_regexp: /^#( |$)/)
        lines = File.readlines(filename)
        lines = lines[1..-1] if lines[0] =~ /^#!/
        lines.take_while { |l| l =~ comment_regexp }.map { |l| l.sub(comment_regexp, '') }
      end

      # Uses #read_header_comment to read the Ruby header from the script
      # calling this method, then prints the header with some useful
      # highlighting for displaying application help.
      #
      # The first header line will be displayed as a headline using
      # TextMethods#headline.
      #
      # Occurrences of the exact string "$0" will be replaced with the actual
      # $0 command line of the running application and highlighted.
      #
      # If +:print+ is false, then nothing is printed and the lines that would
      # have been displayed are returned in an Array.
      def print_header_help(filename = caller_locations(1, 1)[0].absolute_path, print: true)
        # TODO: Markdown formatting?
        # TODO: highlight argument definitions?

        lines = read_header_comment(filename).map(&:rstrip)

        output = [
          "",
          *MB::U.headline(lines.shift, print: false).lines.map(&:rstrip),
          *lines.map { |l| l.gsub("$0", "\e[1m#{$0}\e[0m") },
          "",
        ]

        if print
          puts output
        else
          output
        end
      end
    end
  end
end
