module MB
  module Util
    # Methods to help with benchmarking code performance.
    module BenchmarkMethods
      # Works like the bmbm method in the official Ruby Benchmark gem, but
      # prints the trial run to stderr and the final results as CSV to stdout.
      #
      # Returns the CSV string.
      #
      # Pass nil for +:stderr+ to disable status messages.
      # Pass nil for +:stdout+ to disable CSV printout.
      #
      # A +:prefix+ may be given to add it as another column before the label
      # column, or you can pass a Hash with multiple column names and values.
      #
      # See #ruby_info for an example value to use for +:prefix+.
      #
      # Example:
      #     MB::U.bench_csv(prefix: MB::U.ruby_info) do |b|
      #       b.report('test') do sleep 1 end
      #       b.report('benchmark') do sleep rand end
      #     end
      #
      # Prints:
      #     Benchmark trial run:
      #       test --   0.000044   0.000008   0.000052 (  1.000126)
      #       benchmark --   0.000050   0.000010   0.000060 (  0.418908)
      #       TRIAL TOTAL:   0.000094   0.000018   0.000112 (  1.419034)
      #
      #     Benchmark final run:
      #       test --   0.000033   0.000006   0.000039 (  1.000338)
      #       benchmark --   0.000039   0.000000   0.000039 (  0.728009)
      #       FINAL TOTAL:   0.000072   0.000006   0.000078 (  1.728346)
      #
      #       ruby,jit,label,user CPU,system CPU,total CPU,realtime
      #       ruby-3.4.8,false,test,3.299999999997749e-05,5.999999999999062e-06,3.8999999999976553e-05,1.0003375739997864
      #       ruby-3.4.8,false,benchmark,3.900000000001125e-05,0.0,3.900000000001125e-05,0.7280085390011664
      #       ruby-3.4.8,false,TOTAL,7.199999999998874e-05,5.999999999999062e-06,7.79999999999878e-05,1.7283461130009528
      def bench_csv(prefix: nil, stderr: $stderr, stdout: $stdout)
        require 'benchmark'
        require 'csv'

        job = ::Benchmark::Job.new(0)
        yield job

        stderr&.puts "\e[33mBenchmark trial run:"
        trial_results = job.list.map { |label, item|
          stderr&.write "  #{label}..."

          result = Benchmark.measure(label, &item)
          stderr&.puts "\b\b\b -- #{result}"

          result
        }
        stderr&.puts "  TRIAL TOTAL: #{trial_results.sum(::Benchmark::Tms.new)}"

        stderr&.puts "\n\e[1;36mBenchmark final run:\e[22m"
        final_results = job.list.map { |label, item|
          # Running GC before each final test is what the benchmark gem does,
          # but it seems odd not to do it before each trial run too.
          GC.start
          stderr&.write "  #{label}..."

          result = Benchmark.measure(label, &item)
          stderr&.puts "\b\b\b -- #{result}"

          result
        }
        final_total = final_results.sum(::Benchmark::Tms.new)
        stderr&.puts "  \e[1mFINAL TOTAL: #{final_total}\e[0m"

        prefix = { '' => prefix }.compact unless prefix.is_a?(Hash)
        headers = [*prefix.keys, 'label', 'user CPU', 'system CPU', 'total CPU', 'realtime']

        csv = CSV.new('', headers: headers, write_headers: true)
        final_results.each do |result|
          csv.add_row [*prefix.values, result.label, result.utime, result.stime, result.total, result.real]
        end

        csv.add_row [*prefix.values, 'TOTAL', final_total.utime, final_total.stime, final_total.total, final_total.real]

        csv.string.tap { |s|
          stdout&.puts s
        }
      end

      # Returns true if MJIT, YJIT, or RJIT is enabled, false otherwise.
      def jit_enabled?
        (defined?(RubyVM::MJIT) && RubyVM::MJIT.respond_to?(:enabled?) && RubyVM::MJIT.enabled?) ||
          (defined?(RubyVM::YJIT) && RubyVM::YJIT.respond_to?(:enabled?) && RubyVM::YJIT.enabled?) ||
          (defined?(RubyVM::RJIT) && RubyVM::RJIT.respond_to?(:enabled?) && RubyVM::RJIT.enabled?) ||
          (defined?(RubyVM::JIT) && RubyVM::JIT.respond_to?(:enabled?) && RubyVM::JIT.enabled?) ||
          false
      end

      # Returns a Hash with the engine, version number, and JIT status of the
      # Ruby VM.  This may be passed to the +:prefix+ parameter of #bench_csv.
      def ruby_info
        { ruby: [RUBY_ENGINE, RUBY_ENGINE_VERSION, RUBY_VERSION].compact.uniq.join('-'), jit: MB::U.jit_enabled? }
      end
    end
  end
end
