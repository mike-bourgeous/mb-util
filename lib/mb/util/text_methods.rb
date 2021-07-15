module MB
  module Util
    # Methods related to highlighting data, code, or text, or modifying text.
    #
    # Some of these functions will use Pry or CodeRay if available.
    #
    # MB::Util extends itself with this module, so use these methods via
    # MB::Util.
    module TextMethods
      # Wraps the given text for the current terminal width, or 80 columns if
      # the terminal width is unknown.  Returns the text unmodified if WordWrap
      # is unavailable.
      def wrap(text, width: self.width)
        require 'word_wrap'
        WordWrap.ww(text, width - 1, true) # FIXME: doesn't ignore ANSI escapes
      rescue LoadError
        Kernel.warn 'Failed to load the WordWrap gem'
        text
      end

      # Returns a copy of the String with ANSI-style escape sequences removed.
      def remove_ansi(str)
        str.gsub(/\e\[[^A-Za-z~]*[A-Za-z~]/, '')
      end

      # Returns a String with a syntax highlighted form of the given +object+,
      # using Pry's ColorPrinter.  If the ColorPrinter is not available,
      # CodeRay will be used, and failing that, the string will be bolded.
      def highlight(object, columns: nil)
        require 'pry'
        Pry::ColorPrinter.pp(object, '', columns || width)
      rescue LoadError
        Kernel.warn 'Failed to load Pry for pretty-printing'
        begin
          syntax(object.inspect)
        rescue LoadError
          "\e[1m#{object.inspect}\e[0m"
        end
      end

      # Returns a String with the given Ruby code highlighted by CodeRay.  If
      # CodeRay is not available, then a simple character highlight will be
      # applied.
      def syntax(code, language = :ruby)
        require 'coderay'
        CodeRay.scan(code.to_s, language || :ruby).terminal
      rescue LoadError
        Kernel.warn 'Failed to load CodeRay for syntax highlighting'
        code.to_s
          .gsub(/[0-9]+/, "\e[34m\\&\e[37m")
          .gsub(/[[:upper:]][[:alpha:]_]+/, "\e[32m\\&\e[37m")
          .gsub(/[{}=<>]+/, "\e[33m\\&\e[37m")
          .gsub(/["'`]+/, "\e[35m\\&\e[37m")
          .gsub(/[:,]+/, "\e[36m\\&\e[37m")
      end

      # Prints the given +data+ (either a Hash mapping column names to Arrays,
      # or an Array of Arrays of data) in a tabular layout with color
      # highlighting.
      #
      # If +:header+ is false, then a header will not be printed.  If +:header+
      # is an Array, then its contents will be used as column labels.  If
      # +:header+ is nil, then Hash keys will be used as column labels for a
      # Hash, and 1-based indices will be used for an Array.
      #
      # If +:show_nil+ is false (the default), then nil data values will not be
      # displayed.  If true, then nil data values will be printed as "nil".
      #
      # If +:separate_rows+ is true, then data rows will have a separator
      # printed between them.  If false (the default), then only the header row
      # will have a separator after it.
      def table(data, header: nil, show_nil: false, separate_rows: false)
        if data.is_a?(Hash)
          header = data.keys
          rows = data.values.map { |v| Array(v) }
          maxlen = rows.map(&:length).max
          rows.map! { |r|
            if r.length >= maxlen
              r
            else
              r + Array.new(maxlen - r.length)
            end
          }
          rows = rows.transpose
        else
          rows = data
        end

        rows = Array(rows)
        rows = rows.map { |r| Array(r).dup }
        columns = rows.map(&:length).max
        rows.each { |r| r[columns - 1] = nil if r.length < columns }

        if header != false
          header = (1..columns).map(&:to_s) if header.nil?
          header = Array(header)
          header[columns - 1] = nil if header.length < columns
          header = header.map(&:to_s)
          header_width = 2 + header.map(&:length).max
        end

        formatted = rows.map { |r|
          r.map { |v|
            (!show_nil && v.nil?) ? '' : MB::U.highlight(v).strip
          }
        }

        column_width = 2 + formatted.flatten.map { |hl|
          MB::U.remove_ansi(hl).length
        }.max
        column_width = header_width if header_width && header_width > column_width

        separator = (['-' * column_width] * columns).join('+')

        if header
          puts header.map.with_index { |k, idx| "\e[1;#{31 + idx % 7}m#{k.to_s.center(column_width)}\e[0m" }.join('|')
          puts separator
        end

        formatted.each_with_index do |row, idx|
          puts(
            row.map { |hl|
              colorless = MB::U.remove_ansi(hl)
              len = colorless.length
              extra = column_width - len
              # TODO: align on the decimal point
              # pre = extra / 2
              pre = colorless.start_with?('-') ? 0 : 1
              post = extra - pre
              post = 0 if post < 0
              "#{' ' * pre}#{hl}#{' ' * post}"
            }.join('|')
          )
          puts separator if separate_rows && idx < formatted.length - 1
        end

        nil
      end
    end
  end
end
