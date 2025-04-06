RSpec.describe(MB::U::DebugMethods, :aggregate_failures) do
  describe '#all_threads_backtrace' do
    it 'prints a backtrace for each thread' do
      t1 = Thread.new do sleep end
      t1.name = 'Thread one'

      t2 = Thread.new do sleep end
      t2.name = 'Thread two'

      expect(Thread.list.count).to be >= 3

      Thread.list.count.times do
        expect(MB::Util).to receive(:puts).with(/Thread \d/)
        expect(MB::Util).to receive(:puts).with(/rspec|sleep|timeout|^$/)
      end

      MB::U.all_threads_backtrace

    ensure
      t1&.kill
      t2&.kill
    end
  end

  describe '#sigquit_backtrace' do
    it 'works correctly in the example program' do
      # Maybe there's a way to simulate a trap/signal in RSpec, but just
      # calling out to another program seems easy enough
      output = `bin/sigquit_example.rb 2>&1`
      expect($?.success?).to eq(true)

      expect(output).to include('Thread 1')
      expect(output).to include('Thread 2')
      expect(output).to include('Thread 3')
      expect(output).to include('Thread 4')
      expect(output).to include('Thread 5')
      expect(output).to include('f1')
      expect(output).to include('f2')
      expect(output).to include('f3')
      expect(output).to include('sleep')
      expect(output).to include('Shutting down')
    end
  end
end
