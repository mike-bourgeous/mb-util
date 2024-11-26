RSpec.describe(MB::U::DebugMethods, :aggregate_failures) do
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
