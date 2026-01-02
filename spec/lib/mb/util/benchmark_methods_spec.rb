RSpec.describe(MB::Util::BenchmarkMethods, aggregate_failures: true) do
  describe '#bench_csv' do
    let(:err) { String.new }
    let(:out) { String.new }
    let(:errio) { StringIO.new(err) }
    let(:outio) { StringIO.new(out) }
    let(:prefix) { nil }
    let(:bench) {
      MB::U.bench_csv(prefix: prefix, stderr: errio, stdout: outio) do |b|
        b.report 'one' do sleep 0.01 end
        b.report 'two' do sleep 0.02 end
      end
    }

    it 'writes CSV to stdout' do
      expect(bench.strip).to eq(out.strip)
      expect(err).to include("\b")
      expect(err).to include("TOTAL")

      lines = bench.lines
      expect(lines[0]).to match(/^label.*real/)
      expect(lines[1]).to match(/^one(,[^,]*){4}/)
      expect(lines[2]).to match(/^two/)
      expect(lines[3]).to match(/^TOTAL/)
      expect(lines.length).to eq(4)
    end

    context 'when output is disabled' do
      let(:errio) { nil }
      let(:outio) { nil }

      it 'still returns CSV if output is disabled' do
        expect(err).to be_empty
        expect(out).to be_empty

        lines = bench.lines
        expect(lines[0]).to match(/^label.*real/)
        expect(lines.length).to eq(4)
      end
    end

    context 'with a literal prefix' do
      let(:prefix) { 'test prefix' }

      it 'adds the prefix' do
        expect(bench).to start_with('"",label')
      end
    end

    context 'with a Hash prefix' do
      let(:prefix) { { col1: 'Prefix one', col2: 2 } }

      it 'adds the prefix' do
        expect(bench).to start_with('col1,col2,label')
        expect(bench.lines[1]).to start_with('Prefix one,2,one')
      end
    end
  end

  describe '#jit_enabled?' do
    it 'returns true if JIT was enabled with RUBYOPT' do
      expect(`RUBYOPT=--jit ./spec/scripts/jit_enabled.rb`.strip).to eq('true')
    end

    it 'returns false if JIT was not enabled' do
      expect(`RUBYOPT='' ./spec/scripts/jit_enabled.rb`.strip).to eq('false')
    end
  end

  describe '#ruby_info' do
    it 'returns a hash with JIT status and Ruby version' do
      expect(MB::U.ruby_info).to eq({ ruby: [RUBY_ENGINE, RUBY_ENGINE_VERSION, RUBY_VERSION].compact.uniq.join('-'), jit: MB::U.jit_enabled? })
    end
  end
end
