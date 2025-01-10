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

      # Returns a terminal escape sequence to produce an approximate RGB color
      # from the xterm-256color 6x6x6 RGB cube for the given RGB integer values
      # from 0..255.  If r == g == b, then one of the 24 grays at the end of
      # the 256-color palette may be used instead.
      #
      # If +:background+ is true, then generates a background color (48;5;...)
      # instead of a foreground color (38;5;...).
      def rgb256(r, g, b, background: false)
        # TODO: Maybe use a closest-match palette lookup algorithm instead of hard-coding a special behavior for r==g==b

        # 246.5 is 0.5 * (0xee + 0xff) (xterm grays increment by 10 from 8 and top out at 238 / 0xee)
        # Reference used: https://en.wikipedia.org/wiki/ANSI_escape_code#8-bit
        if r == g && g == b && r >= 4 && r <= 246.5
          gray = ((r - 8) / 10).round
          gray = 0 if gray < 0
          gray = 23 if gray > 23

          index = 232 + gray
        else
          r = xterm256_lookup(r)
          g = xterm256_lookup(g)
          b = xterm256_lookup(b)

          index = 16 + r * 36 + g * 6 + b
        end

        "\e[#{background ? 48 : 38};5;#{index}m"
      end

      # Returns a terminal escape sequence to produce a 24-bit color for the
      # given RGB integer values from 0..255.
      #
      # if +:fallback+ is true, then the RGB color sequence is prefixed by a
      # fallback from the xterm-256color palette.
      #
      # If +:background+ is true, then generates a background color (48;2;...)
      # instead of a foreground color (38;2;...).
      def rgb(r, g, b, fallback: false, background: false)
        r = r.round
        g = g.round
        b = b.round
        r = 0 if r < 0
        r = 255 if r > 255
        g = 0 if g < 0
        g = 255 if g > 255
        b = 0 if b < 0
        b = 255 if b > 255

        "#{rgb256(r, g, b, background: background) if fallback}\e[#{background ? 48 : 38};2;#{r};#{g};#{b}m"
      end

      # Returns a terminal escape sequence for the given HSV color.  H, S, and
      # V are floats in the range 0..1.
      #
      # if +:fallback+ is true, then the RGB color sequence is prefixed by a
      # fallback from the xterm-256color palette.
      #
      # If +:background+ is true, then generates a background color (48;2;...)
      # instead of a foreground color (38;2;...).
      def hsv(h, s, v, fallback: false, background: false)
        r, g, b = hsv_to_rgb(h, s, v)

        rgb(r * 255, g * 255, b * 255, fallback: fallback, background: background)
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
          Pry::ColorPrinter.pp(object, '', columns || width).strip!
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
      #
      # Will also colorize an Array of Strings from #caller or Exception's
      # #backtrace, but this is more brittle and will probably only work if the
      # language is set to English.
      #
      # The +:exclude+ parameter may be a regular expression.  Any backtrace
      # element that matches the regular epxression will be excluded.
      #
      # The +:prefix+ parameter is prepended to each line.  This may be used
      # for adding indentation or timestamps.
      #
      # If +:trace_causes+ is false, then exception causes are not added to the
      # message.
      def color_trace(trace, exclude: nil, prefix: nil, trace_causes: true)
        case trace
        when Array
          unless trace.all? { |t| t.is_a?(Thread::Backtrace::Location) || t.is_a?(String) }
            raise TraceArgumentError
          end

          home = Dir.home

          trace = trace.reject { |t| t.to_s =~ exclude } if exclude
          trace.map { |t|
            case t
            when Thread::Backtrace::Location
              fullpath = t.path
              line = t.lineno
              label = t.label

            when /^(?<fullpath>.*):(?<line>[0-9]*):in `(?<label>.*)'.*$/
              fullpath = $1
              line = $2
              label = $3

            when String
              fullpath, line, label = t.split(':', 3)

            else
              raise TraceArgumentError
            end

            path, sep, name = fullpath.rpartition('/')
            path = path.sub(/^#{Regexp.escape(home)}/, '~')

            "#{prefix}\e[38;5;240m#{path}#{sep}\e[36m#{name}\e[38;5;240m:\e[1;34m#{line}\e[0;38;5;240m:\e[33min `\e[1;35m#{label}\e[0;33m'\e[0m"
          }.join("\n")

        when Exception
          bt = color_trace(trace.backtrace_locations || trace.backtrace, exclude: exclude, prefix: "#{prefix}\t")
          msg = "#{prefix}\e[31m#<#{trace.class}: \e[1m#{trace.message}\e[22m:\n#{bt}\n\e[0;31m>\e[0m"

          trace_set = {trace: true}
          ex = trace
          while trace_causes && ex.cause && !trace_set.include?(ex.cause)
            # TODO: exclude backtrace lines from prior exceptions
            ex = ex.cause
            trace_set[ex] = true
            cause_trace = color_trace(ex, exclude: exclude, prefix: "#{prefix}\t", trace_causes: trace_causes)
            msg << "\n#{prefix}\t\e[31m... caused by\e[0m #{cause_trace.lstrip}\n"
          end

          msg

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

      # Prints (or returns if +:print+ is false) the given +text+, followed by
      # a double underline composed of a string of +:underline+ of the same
      # length, using the given ANSI/xterm +:color+.  The +:prefix+ string, if
      # present, will be prepended to both lines of the headline, without
      # color.  If printing, an extra newline is printed before the text.
      def headline(text, color: '1;33', underline: '=', print: true, prefix: nil)
        len = remove_ansi(text).length
        str = "#{prefix}\e[#{color}m#{text}\e[0m\n#{prefix}\e[#{color}m#{underline * len}\e[0m"

        if print
          puts "\n#{str}\n"
        else
          str
        end
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
      # same width.  If +:variable_width+ is an Integer, then that value will
      # be used as the size for columns.  If +:variable_width+ is an Array of
      # Integers, then those values will be used as minimum sizes for columns.
      #
      # If +:print+ is true (the default), then the table will be printed to
      # STDOUT.  If false, then the formatted rows of the table will be
      # returned as an Array of Strings.
      #
      # If +:unicode+ is true, then Unicode box drawing characters are used
      # instead of ASCII to draw the table borders.
      def table(data, header: nil, show_nil: false, separate_rows: false, raw_strings: true, variable_width: false, print: true, unicode: false)
        if unicode
          vertical = "\u2502"
          horizontal = "\u2500"
          intersection = "\u253c"
        else
          vertical = '|'
          horizontal = '-'
          intersection = '+'
        end

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
        columns = rows.map(&:length).max || 0
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

        variable_width = [variable_width] * columns if variable_width.is_a?(Integer) && variable_width > 0

        if formatted.empty?
          column_width = header_width.dup
        else
          column_width = formatted.map { |row|
            row.map { |hl| MB::U.remove_ansi(hl).length }
          }.transpose.map.with_index { |col, idx|
            vw = variable_width[idx] if variable_width.is_a?(Array)
            [(vw || 0) + 2, col.max + 2, header_width[idx] || 0].max
          }
        end

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

        separator = column_width.map { |w| horizontal * w }.join(intersection)

        if header.is_a?(String)
          output << center_ansi("\e[1m#{header}\e[0m", total_width)
          output << separator
        elsif header
          output << header.map.with_index { |k, idx|
            width = column_width[idx] || header_width[idx] || 0
            "\e[1;#{31 + idx % 7}m#{center_ansi(k.to_s, width)}\e[0m"
          }.join(vertical)
          output << separator
        end

        formatted.each.with_index { |row, idx|
          output << row.map.with_index { |hl, col|
            colorless = MB::U.remove_ansi(hl)
            len = colorless.length
            extra = column_width[col] - len
            # TODO: align numerics on the decimal point
            # TODO: maybe allow specifying right-aligned or center-aligned
            pre = colorless.start_with?('-') ? 0 : 1
            post = extra - pre
            post = 0 if post < 0
            "#{' ' * pre}#{hl}#{' ' * post}"
          }.join(vertical)

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

      private

      # The xterm-256color RGB cube does not use a linear scale from sRGB
      # values in 0..255.  This function uses a lookup table to convert from
      # the 0..255 RGB range to the 0..5 xterm-256color range.
      def xterm256_lookup(v)
        # Reference used: https://en.wikipedia.org/wiki/ANSI_escape_code#8-bit
        case
        when v < 47.5
          0 # 0

        when v < 115
          1 # 95

        when v < 155
          2 # 135

        when v < 195
          3 # 175

        when v < 235
          4 # 215

        else
          5 # 255
        end
      end

      # Converts HSV in the range 0..1 to RGB in the range 0..1.  Alpha is
      # returned unmodified if present, omitted if nil.
      #
      # Borrowed from mb-geometry (removed alpha channel and GC-free support):
      # https://github.com/mike-bourgeous/mb-geometry/blob/5e18eb910c182b99755b852f133f0b8579372884/lib/mb/geometry/voronoi/svg.rb#L6-L50
      def hsv_to_rgb(h, s, v)
        # https://en.wikipedia.org/wiki/HSL_and_HSV#HSV_to_RGB

        h = h.to_f
        s = s.to_f
        v = v.to_f

        h = 0 if h.nan?
        h = 0 if h < 0 && h.infinite?
        h = 1 if h > 1 && h.infinite?
        h = h % 1 if h < 0 || h > 1
        c = v.to_f * s.to_f
        h *= 6.0
        x = c.to_f * (1 - ((h % 2) - 1).abs)
        case h.floor
        when 0
          r, g, b = c, x, 0
        when 1
          r, g, b = x, c, 0
        when 2
          r, g, b = 0, c, x
        when 3
          r, g, b = 0, x, c
        when 4
          r, g, b = x, 0, c
        else
          r, g, b = c, 0, x
        end

        m = v - c

        return r + m, g + m, b + m
      end
    end
  end
end
