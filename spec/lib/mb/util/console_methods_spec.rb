RSpec.describe(MB::Util::ConsoleMethods) do
  [:width, :height].each do |m|
    describe "##{m}" do
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
