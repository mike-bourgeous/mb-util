RSpec.describe(MB::Util::TextMethods) do
  describe '#highlight' do
    it 'includes some ANSI colors when given a Hash' do
      expect(MB::Util.highlight({a: 1})).to match(/\e\[[^a-z]*m/)
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

  describe '#table' do
    it 'can print a hash' do
      expect(MB::Util).to receive(:puts).with(/a.*\|.*b.*\|.*c/)
      expect(MB::Util).to receive(:puts).with(/-+\+-+\+-+/)
      expect(MB::Util).to receive(:puts).with(/11.*\|.*22.*\|.*333/)
      expect(MB::Util).to receive(:puts).with(/37.*\|.*27.*\|.*17/)
      expect(MB::Util).to receive(:puts).with(/7.*\|.*z.*\|[^nil]*$/)
      MB::U.table({a: [11, 37, 7], b: [22, 27, 'z'], c: [333, 17]})
    end

    it 'can print an array' do
      expect(MB::Util).to receive(:puts).with(/1.*\|.*2.*\|.*3.*\|.*4/)
      expect(MB::Util).to receive(:puts).with(/-+\+-+\+-+/)
      expect(MB::Util).to receive(:puts).with(/11.*\|.*22.*\|.*333.*\|[^nil]*$/)
      expect(MB::Util).to receive(:puts).with(/37.*\|.*27.*\|.*17.*\|/)
      expect(MB::Util).to receive(:puts).with(/7.*\|.*z.*\|[^nil|]*\|[^nil|]*$/)
      MB::U.table([
        [11, 22, 333],
        [37, 27, 17, 0],
        [7, 'z']
      ])
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
  end
end
