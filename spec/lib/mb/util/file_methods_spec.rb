require 'fileutils'

RSpec.describe(MB::Util::FileMethods) do
  describe '#read_header_comment' do
    it 'can read the header comment lines from a Ruby script' do
      header = MB::U.read_header_comment('bin/console').join
      expect(header).to match(/Pry/m)
      expect(header).not_to match(/^require /m)
    end
  end

  describe '#prevent_overwrite' do
    let(:name) { 'tmp/prevent_overwrite_test' }

    before(:all) {
      FileUtils.mkdir_p('tmp')
    }

    context 'when prompt is true' do
      it 'does nothing if the file does not exist' do
        File.unlink(name) rescue nil

        expect(STDIN).not_to receive(:readline)
        expect(STDOUT).not_to receive(:write)

        expect { MB::Util.prevent_overwrite(name, prompt: true) }.not_to raise_error
      end

      it 'does nothing if the user chooses to overwrite' do
        FileUtils.touch(name)

        expect(STDIN).to receive(:readline).and_return('Yo')
        expect(STDOUT).to receive(:write).at_least(2).times

        expect { MB::Util.prevent_overwrite(name, prompt: true) }.not_to raise_error
      end

      it 'raises an error if the user chooses not to overwrite' do
        FileUtils.touch(name)

        expect(STDIN).to receive(:readline).and_return('Nay')
        expect(STDOUT).to receive(:write).at_least(2).times

        expect { MB::Util.prevent_overwrite(name, prompt: true) }.to raise_error(MB::Util::FileMethods::FileExistsError)
      end

      it 'prompts until either yes or no is received' do
        FileUtils.touch(name)

        expect(STDIN).to receive(:readline).and_return('a')
        expect(STDIN).to receive(:readline).and_return('b')
        expect(STDIN).to receive(:readline).and_return('n')

        expect(STDOUT).to receive(:write).with(/#{name}/)
        expect(STDOUT).to receive(:write).with(/Y.*N/).exactly(3).times
        expect(STDOUT).to receive(:write).with(/Not overwriting/)

        expect { MB::Util.prevent_overwrite(name, prompt: true) }.to raise_error(MB::Util::FileMethods::FileExistsError)

        expect(STDIN).to receive(:readline).and_return('y')

        expect(STDOUT).to receive(:write).with(/#{name}/)
        expect(STDOUT).to receive(:write).with(/Y.*N/)
        expect(STDOUT).to receive(:write).with(/Overwriting/)

        expect { MB::Util.prevent_overwrite(name, prompt: true) }.not_to raise_error
      end
    end

    context 'when prompt is false' do
      it 'does nothing if the file does not exist' do
        File.unlink(name) rescue nil
        expect { MB::Util.prevent_overwrite(name, prompt: false) }.not_to raise_error
      end

      it 'raises an error if the file exists' do
        FileUtils.touch(name)
        expect(STDOUT).to receive(:write).with(/Not overwriting/)
        expect { MB::Util.prevent_overwrite(name, prompt: false) }.to raise_error(MB::Util::FileMethods::FileExistsError)
      end
    end
  end
end
