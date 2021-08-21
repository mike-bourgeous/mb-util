module MB
  module Util
    # Methods related to highlighting data, code, or text, or modifying text.
    #
    # Some of these functions will use Pry or CodeRay if available.
    #
    # MB::Util extends itself with this module, so use these methods via
    # MB::Util.
    module TextMethods
      # Raised by #color_trace if given the wrong type of argument.
      class TraceArgumentError < ArgumentError
        def initialize(msg = nil)
          msg ||= 'Provide an Array from caller_locations/backtrace_locations or an Exception'
          super(msg)
        end
      end

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

      # Returns a copy of +str+ centered in a width of +columns+ characters,
      # disregarding ANSI sequences.  All whitespace characters in the String
      # will be replaced with spaces.
      def center_ansi(str, columns)
        str = str.gsub(/\s/, ' ')
        length = remove_ansi(str).length

        extra = columns - length
        pre = extra / 2
        pre = 0 if pre < 0
        post = extra - pre
        post = 0 if post < 0

        "#{' ' * pre}#{str}#{' ' * post}"
      end

      # Returns a String with a syntax highlighted form of the given +object+,
      # using Pry's ColorPrinter.  If the ColorPrinter is not available,
      # CodeRay will be used, and failing that, the string will be bolded.
      def highlight(object, columns: nil)
        if object.is_a?(Exception) || (object.is_a?(Array) && object[0].is_a?(Thread::Backtrace::Location))
          color_trace(object)
        else
          require 'pry'
          Pry::ColorPrinter.pp(object, '', columns || width)
        end
      rescue LoadError
        Kernel.warn 'Failed to load Pry for pretty-printing'
        begin
          syntax(object.inspect)
        rescue LoadError
          "\e[1m#{object.inspect}\e[0m"
        end
      end

      # Colorizes a backtrace from caller_locations, or an exception with its
      # backtrace.  Used by #highlight, but may also be used directly.
      def color_trace(trace)
        case trace
        when Array
          raise TraceArgumentError unless trace.all?(Thread::Backtrace::Location)
          home = Dir.home
          trace.map { |t|
            path, sep, name = t.path.rpartition('/')
            path = path.sub(/^#{Regexp.escape(home)}/, '~')
            "\e[38;5;240m#{path}#{sep}\e[36m#{name}\e[38;5;240m:\e[1;34m#{t.lineno}\e[0;38;5;240m:\e[33min `\e[1;35m#{t.label}\e[0;33m'\e[0m"
          }.join("\n")

        when Exception
          "\e[31m#<#{trace.class}: \e[1m#{trace.message}\e[22m:\n\t#{color_trace(trace.backtrace_locations).gsub("\n", "\n\t")}\n\e[0;31m>\e[0m"

        when nil
          '[no trace]'

        else
          raise TraceArgumentError
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
      # +:header+ is nil (the default), then Hash keys will be used as column
      # labels for a Hash, and 1-based indices will be used for an Array.  If
      # +:header+ is a String, then the table header will be a single column
      # with the String centered within.
      #
      # If +:show_nil+ is false (the default), then nil data values will not be
      # displayed.  If true, then nil data values will be printed as "nil".
      #
      # If +:separate_rows+ is true, then data rows will have a separator
      # printed between them.  If false (the default), then only the header row
      # will have a separator after it.
      #
      # If +:raw_strings+ is false (the default is true), then strings will be
      # syntax highlighted and displayed with quotation marks.
      #
      # If +:variable_width+ is true (the default is false), then each column
      # may have a different width.  If false, then all columns will be the
      # same width.
      #
      # If +:print+ is true (the default), then the table will be printed to
      # STDOUT.  If false, then the formatted rows of the table will be
      # returned as an Array of Strings.
      def table(data, header: nil, show_nil: false, separate_rows: false, raw_strings: true, variable_width: false, print: true)
        if data.is_a?(Hash)
          header = data.keys if header.nil?
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
        columns = header.length if header.is_a?(Array) && header.length > columns
        rows.each { |r| r[columns - 1] = nil if r.length < columns }

        case header
        when String
          # TODO: there might be a better way to expand columns to fit the
          # header width; see code below
          header_width = []

        when false
          header_width = []

        else
          header = (1..columns).map(&:to_s) if header.nil?
          header = header.is_a?(Array) ? header.dup : Array(header)
          header[columns - 1] = nil if header.length < columns
          header = header.map(&:to_s)
          header_width = header.map { |h| MB::U.remove_ansi(h).length + 2 }
        end

        formatted = rows.map { |r|
          r.map { |v|
            case v
            when nil
              show_nil ? MB::U.highlight(v).strip : ''

            when String
              raw_strings ? v : MB::U.highlight(v).strip

            else
              MB::U.highlight(v).strip
            end
          }
        }

        column_width = formatted.map { |row|
          row.map { |hl| MB::U.remove_ansi(hl).length + 2 }
        }.transpose.map.with_index { |col, idx|
          [col.max, header_width[idx] || 0].max
        }

        column_width = [column_width.max] * column_width.length unless variable_width
        total_width = column_width.sum + column_width.length - 1

        output = []

        if header.is_a?(String)
          header_length = remove_ansi(header).length + 2

          # FIXME: this is a slow algorithm design for growing the smallest columns first
          while total_width < header_length
            if variable_width
              shortest_idx = column_width.each.with_index.min_by(&:first).last
              column_width[shortest_idx] += 1
              total_width += 1
            else
              column_width.map! { |c| c + 1 }
              total_width += column_width.length
            end
          end
        end

        separator = column_width.map { |w| '-' * w }.join('+')

        if header.is_a?(String)
          output << center_ansi("\e[1m#{header}\e[0m", total_width)
          output << separator
        elsif header
          output << header.map.with_index { |k, idx|
            width = column_width[idx] || header_width[idx] || 0
            "\e[1;#{31 + idx % 7}m#{center_ansi(k.to_s, width)}\e[0m"
          }.join('|')
          output << separator
        end

        formatted.each.with_index { |row, idx|
          output << row.map.with_index { |hl, col|
            colorless = MB::U.remove_ansi(hl)
            len = colorless.length
            extra = column_width[col] - len
            # TODO: align numerics on the decimal point
            pre = colorless.start_with?('-') ? 0 : 1
            post = extra - pre
            post = 0 if post < 0
            "#{' ' * pre}#{hl}#{' ' * post}"
          }.join('|')

          if separate_rows && idx < formatted.length - 1
            output << separator
          end
        }

        if print
          output.each do |s|
            puts s
          end
          nil
        else
          output
        end
      end
    end
  end
end
