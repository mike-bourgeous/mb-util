require 'timeout'

RSpec.describe(MB::Util::TextMethods) do
  describe '#highlight' do
    it 'includes some ANSI colors when given a Hash' do
      expect(MB::Util.highlight({a: 1})).to match(/\e\[[^a-z]*m/)
    end

    it 'calls color_trace for caller_locations' do
      expect(MB::Util).to receive(:color_trace).and_return('test here')
      text = MB::Util.highlight(caller_locations)
      expect(text).to eq('test here')
    end

    it 'calls color_trace for exceptions' do
      expect(MB::Util).to receive(:color_trace).and_return('test here')
      text = MB::Util.highlight(RuntimeError.new)
      expect(text).to eq('test here')
    end
  end

  describe '#color_trace' do
    it 'raises an error if given invalid types' do
      expect { MB::U.color_trace(['invalid array']) }.to raise_error(MB::Util::TextMethods::TraceArgumentError)
      expect { MB::U.color_trace('invalid arg') }.to raise_error(MB::Util::TextMethods::TraceArgumentError)
    end

    it 'formats caller locations' do
      locations = caller_locations
      expect(locations.length).to be > 2
      expect(MB::U.color_trace(locations).lines.count).to eq(locations.length)
      expect(MB::U.color_trace(locations)).to match(/\e\[0m/)
    end

    it 'formats exceptions with a backtrace' do
      error = nil
      begin
        error = MB::U.color_trace('invalid')
      rescue => e
        error = e
      end

      text = MB::U.color_trace(error)
      expect(text).to include('TraceArgumentError')
      expect(text).to include('Provide')
      expect(text.lines.count).to be > 2
    end

    it 'can format an exception without a backtrace' do
      error = RuntimeError.new
      expect(error.backtrace_locations).to be_nil
      expect(MB::U.color_trace(error)).to include('no trace')
    end
  end

  describe '#syntax' do
    it 'includes some ANSI colors when given some code' do
      expect(MB::Util.syntax("def x; {a: 1}; end")).to match(/\e\[[^a-z]*m/)
    end
  end

  describe '#remove_ansi' do
    it 'can remove color codes from text' do
      input = "\e[1mBold\e[0m \e[34mBlue\e[0m \e[1;32mBright Green\e[0m \e[48;2;100;50;50mRust Background\e[0m"
      expected = "Bold Blue Bright Green Rust Background"
      expect(MB::Util.remove_ansi(input)).to eq(expected)
    end

    it 'can remove positioning and clearing codes' do
      input = "Hi\e[H\e[2J\e[12Athere"
      expect(MB::Util.remove_ansi(input)).to eq('Hithere')
    end
  end

  describe '#center_ansi' do
    it 'can center a plain String' do
      expect(MB::Util.center_ansi('abcd', 8)).to eq("  abcd  ")
    end

    it 'can center an ANSI-colored String' do
      orig = "\e[1ma\e[33mb\e[36mc\e[22md\e[0m"
      expect(MB::Util.center_ansi(orig, 8)).to eq("  #{orig}  ")
      expect(MB::Util.center_ansi(orig, 10)).to eq("   #{orig}   ")
    end

    it 'returns the original String if the length is greater than the number of columns' do
      expect(MB::Util.center_ansi('abcd', 1)).to eq('abcd')
    end
  end

  describe '#headline' do
    it 'generates the correct length without ANSI sequences' do
      result = MB::U.headline('yo yo', underline: '-', print: false)
      expect(result).to eq("\e[1;33myo yo\n\e[1;33m-----\e[0m")
    end

    it 'generates the correct length with ANSI sequences' do
      result = MB::U.headline("\e[1;35mHeyo\e[0;36m there\e[0m", color: 35, print: false)
      expect(result).to eq("\e[35m\e[1;35mHeyo\e[0;36m there\e[0m\n\e[35m==========\e[0m")
    end

    it 'prefixes with another newline when printing' do
      expect(MB::Util).to receive(:puts).with("\n\e[1;33mHey\n\e[1;33m^^^\e[0m\n")
      MB::U.headline('Hey', underline: '^')
    end
  end

  describe '#table' do
    context 'with empty inputs' do
      it 'does not loop forever if given an empty Array' do
        expect(MB::U).to receive(:puts).with('')
        expect(MB::U).to receive(:puts).with('')

        expect {
          Timeout.timeout(5) do
            MB::U.table([])
          end
        }.not_to raise_error
      end

      it 'does not loop forever if given an empty Hash' do
        expect(MB::U).to receive(:puts).with('')
        expect(MB::U).to receive(:puts).with('')

        expect {
          Timeout.timeout(5) do
            MB::U.table({})
          end
        }.not_to raise_error
      end

      it 'can display a Hash with empty columns' do
        expect(MB::Util).to receive(:puts).with(/[^ |]* [^ |]*1[^ |]* [^ |*]/)
        expect(MB::Util).to receive(:puts).with('---')
        MB::U.table({1 => []})
      end
    end

    it 'can use a short String as the header' do
      expect(MB::Util).to receive(:puts).with("   \e[1mTest\e[0m    ")
      expect(MB::Util).to receive(:puts).with('---+---+---')
      expect(MB::Util).to receive(:puts).with(' a | b | c ')
      MB::U.table({ a: 'a', b: 'b', c: 'c' }, header: 'Test')
    end

    it 'can use a long String as the header with fixed width columns' do
      expect(MB::Util).to receive(:puts).with(" \e[1mTest A Longer Header\e[0m  ")
      expect(MB::Util).to receive(:puts).with('-------+-------+-------')
      expect(MB::Util).to receive(:puts).with(' aa    | bbb   | c     ')
      MB::U.table({ a: 'aa', b: 'bbb', c: 'c' }, header: 'Test A Longer Header')
    end

    it 'can use a long, ANSI-formatted String as the header with variable width columns' do
      expect(MB::Util).to receive(:puts).with(" \e[1m\e[1mTesting \e[33mLong \e[32mHeaders\e[0m\e[0m ")
      expect(MB::Util).to receive(:puts).with('-------+-------+------')
      expect(MB::Util).to receive(:puts).with(' a     | bbbbb | cc   ')
      MB::U.table({ a: 'a', b: 'bbbbb', c: 'cc' }, header: "\e[1mTesting \e[33mLong \e[32mHeaders\e[0m", variable_width: true)
    end

    it 'can print fixed-width columns' do
      expect(MB::Util).to receive(:puts).with(/1.*\|.*2.*\|.*3/)
      expect(MB::Util).to receive(:puts).with('--------+--------+--------')
      expect(MB::Util).to receive(:puts).with(' a      | b      | cdefgh ')
      MB::U.table([['a', 'b', 'cdefgh']])
    end

    it 'can print variable-width columns' do
      expect(MB::Util).to receive(:puts).with(/1.*\|.*2.*\|.*3.*\|.*4/)
      expect(MB::Util).to receive(:puts).with('---+----+--------+---')
      expect(MB::Util).to receive(:puts).with(' a | b2 | cdefgh | i ')
      MB::U.table([['a', 'b2', 'cdefgh', 'i']], variable_width: true)
    end

    it 'can specify the width of columns' do
      v = MB::U.table([[1, 2, 3], [6, 5, 4]], header: ['a', 'b', 'c'], variable_width: [5, 1, 3], print: false)
      v.map! { |s| MB::Util.remove_ansi(s) }

      expect(v).to eq([
        '   a   | b |  c  ',
        '-------+---+-----',
        ' 1     | 2 | 3   ',
        ' 6     | 5 | 4   ',
      ])
    end

    it 'can return the formatted lines of text' do
      expect(MB::Util).not_to receive(:puts)
      rows = MB::U.table([['a', 'b2', 'cdefgh', 'i']], variable_width: true, print: false)
      expect(rows.length).to eq(3)
      expect(rows[0]).to match(/1.*\|.*2.*\|.*3.*\|.*4/)
      expect(rows[1]).to match(/(-+\+){3}-+/)
      expect(rows[2]).to match(/a.*\|.*b2.*\|.*cdefgh.*\|.*i/)
    end

    it 'can print a Hash' do
      expect(MB::Util).to receive(:puts).with(/a.*\|.*b.*\|.*c/)
      expect(MB::Util).to receive(:puts).with(/-+\+-+\+-+/)
      expect(MB::Util).to receive(:puts).with(/11.*\|.*22.*\|.*333/)
      expect(MB::Util).to receive(:puts).with(/37.*\|.*27.*\|.*17/)
      expect(MB::Util).to receive(:puts).with(/7.*\|.*z.*\|[^nil]*$/)
      MB::U.table({a: [11, 37, 7], b: [22, 27, 'z'], c: [333, 17]})
    end

    it 'can print a Hash with a custom header' do
      expect(MB::Util).to receive(:puts).with(/q.*\|.*r.*\|.*s/)
      expect(MB::Util).to receive(:puts).with(/-+\+-+\+-+/)
      expect(MB::Util).to receive(:puts).with(/11.*\|.*22.*\|.*333/)
      expect(MB::Util).to receive(:puts).with(/37.*\|.*27.*\|.*17/)
      expect(MB::Util).to receive(:puts).with(/7.*\|.*z.*\|[^nil]*$/)
      MB::U.table({a: [11, 37, 7], b: [22, 27, 'z'], c: [333, 17]}, header: ['q', 'r', 's'])
    end

    it 'can print an Array' do
      expect(MB::Util).to receive(:puts).with(/1.*\|.*2.*\|.*3.*\|.*4/)
      expect(MB::Util).to receive(:puts).with(/-+\+-+\+-+/)
      expect(MB::Util).to receive(:puts).with(/11.*\|.*22.*\|.*333.*\|[^nil]*$/)
      expect(MB::Util).to receive(:puts).with(/37.*\|.*27.*\|.*17.*\|.*0/)
      expect(MB::Util).to receive(:puts).with(/7.*\|.*z.*\|[^nil|]*\|[^nil|]*$/)
      MB::U.table([
        [11, 22, 333],
        [37, 27, 17, 0],
        [7, 'z']
      ])
    end

    it 'can print an Array with a custom header' do
      expect(MB::Util).to receive(:puts).with(/q.*\|.*r.*\|.*s.*\|.*t/)
      expect(MB::Util).to receive(:puts).with(/-+\+-+\+-+/)
      expect(MB::Util).to receive(:puts).with(/11.*\|.*22.*\|.*333.*\|[^nil]*$/)
      expect(MB::Util).to receive(:puts).with(/37.*\|.*27.*\|.*17.*\|/)
      expect(MB::Util).to receive(:puts).with(/7.*\|.*z.*\|[^nil|]*\|[^nil|]*$/)
      MB::U.table(
        [
          [11, 22, 333],
          [37, 27, 17, 0],
          [7, 'z']
        ],
        header: ['q', 'r', 's', 't']
      )
    end

    it 'can print a header with fewer columns than data' do
      expect(MB::Util).to receive(:puts).with(/q.*\|.*r.*\|.*s.*\|.*/)
      expect(MB::Util).to receive(:puts).with(/-+\+-+\+-+\+-+/)
      expect(MB::Util).to receive(:puts).with(/11.*\|.*22.*\|.*333.*\|[^nil]*$/)
      expect(MB::Util).to receive(:puts).with(/37.*\|.*27.*\|.*17.*\|.*0/)
      expect(MB::Util).to receive(:puts).with(/7.*\|.*z.*\|[^nil|]*\|[^nil|]*$/)
      MB::U.table(
        [
          [11, 22, 333],
          [37, 27, 17, 0],
          [7, 'z']
        ],
        header: ['q', 'r', 's']
      )
    end

    it 'can print a header with more columns than data' do
      expect(MB::Util).to receive(:puts).with(/q.*\|.*r.*\|.*s.*\|.*t.*\|.*u/)
      expect(MB::Util).to receive(:puts).with(/-+\+-+\+-+\+-+\+-+/)
      expect(MB::Util).to receive(:puts).with(/11.*\|.*22.*\|.*333.*\|[^nil]*\|\s*$/)
      expect(MB::Util).to receive(:puts).with(/37.*\|.*27.*\|.*17.*\|.*0.*\|/)
      expect(MB::Util).to receive(:puts).with(/7.*\|.*z.*\|[^nil|]*\|[^nil|]*\|[^nil|]*$/)
      MB::U.table(
        [
          [11, 22, 333],
          [37, 27, 17, 0],
          [7, 'z']
        ],
        header: ['q', 'r', 's', 't', 'u']
      )
    end

    it 'can omit the header' do
      expect(MB::Util).to receive(:puts).with(/11.*\|.*22.*\|.*333/)
      expect(MB::Util).to receive(:puts).with(/37.*\|.*27.*\|.*17/)
      expect(MB::Util).to receive(:puts).with(/7.*\|.*z.*\|[^n]*$/)
      MB::U.table(
        [
          [11, 22, 333],
          [37, 27, 17],
          [7, 'z']
        ],
        header: false
      )
    end

    it 'can print nils' do
      expect(MB::Util).to receive(:puts).with(/a.*\|.*b.*\|.*c/)
      expect(MB::Util).to receive(:puts).with(/-+\+-+\+-+/)
      expect(MB::Util).to receive(:puts).with(/11.*\|.*22.*\|.*333/)
      expect(MB::Util).to receive(:puts).with(/37.*\|.*27.*\|.*17/)
      expect(MB::Util).to receive(:puts).with(/7.*\|.*z.*\|.*nil/)
      MB::U.table({a: [11, 37, 7], b: [22, 27, 'z'], c: [333, 17]}, show_nil: true)
    end

    it 'can print a separator between each row' do
      expect(MB::Util).to receive(:puts).with(/a.*\|.*b.*\|.*c/)
      expect(MB::Util).to receive(:puts).with(/-+\+-+\+-+/)
      expect(MB::Util).to receive(:puts).with(/11.*\|.*22.*\|.*333/)
      expect(MB::Util).to receive(:puts).with(/-+\+-+\+-+/)
      expect(MB::Util).to receive(:puts).with(/37.*\|.*27.*\|.*17/)
      expect(MB::Util).to receive(:puts).with(/-+\+-+\+-+/)
      expect(MB::Util).to receive(:puts).with(/7.*\|.*z.*\|.*nil/)
      MB::U.table({a: [11, 37, 7], b: [22, 27, 'z'], c: [333, 17]}, show_nil: true, separate_rows: true)
    end

    it 'can print strings with escapes and quotes' do
      expect(MB::Util).to receive(:puts).with(/".*abc.*\\t.*".*\|.*".*def.*"/)
      MB::U.table([["abc\t", 'def']], header: false, raw_strings: false)
    end

    it 'can print strings raw without quotes' do
      expect(MB::Util).to receive(:puts).with(/^[^"]*abc\a[^"]*\|[^"]*def[^"]*$/)
      MB::U.table([["abc\a", 'def']], header: false)
    end
  end
end
