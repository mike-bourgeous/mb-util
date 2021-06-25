RSpec.describe(MB::Util) do
  describe '.highlight' do
    it 'includes some ANSI colors when given a Hash' do
      expect(MB::Util.highlight({a: 1})).to match(/\e\[[^a-z]*m/)
    end
  end

  describe '.syntax' do
    it 'includes some ANSI colors when given some code' do
      expect(MB::Util.syntax("def x; {a: 1}; end")).to match(/\e\[[^a-z]*m/)
    end
  end

  describe '.remove_ansi' do
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

  [:width, :height].each do |m|
    describe ".#{m}" do
      it 'returns an integer value' do
        expect(MB::Util.send(m)).to be_a(Integer)
      end

      it 'works even if IO.console returns nil' do
        expect(IO).to receive(:console).at_least(2).times.and_return(nil)
        expect(MB::Util.send(m)).to be_a(Integer)
        expect(IO.console).to be_nil
      end
    end
  end
end
