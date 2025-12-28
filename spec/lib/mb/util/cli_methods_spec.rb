require 'optionparser'

RSpec.describe(MB::Util::CliMethods) do
  describe '#opt_header_help' do
    it 'adds the file header to OptionParser summary' do
      optp = OptionParser.new { |p|
        MB::U.opt_header_help(p, 'bin/console')

        p.on('--blah', 'Blah')
      }

      expect(optp.summarize).to start_with(
        match(/Interactive Pry console/),
        match(/=======================/),
        "\n"
      )

      expect(optp.summarize).to end_with(
        match(%r{Usage.*bin/console}),
        "\n",
        match(/--blah.*Blah/)
      )

    end
  end
end
