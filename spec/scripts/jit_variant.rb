#!/usr/bin/env ruby
# Prints the JIT variant in use, if it is enabled.  Used by the spec for
# MB::Util::BenchmarkMethods#jit_variant.

require 'bundler/setup'
require 'mb-util'

puts MB::U.jit_variant
