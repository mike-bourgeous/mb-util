#!/usr/bin/env ruby
# Prints true if JIT (just-in-time compilation) is enabled, false if not.
# Used by the spec for MB::Util::BenchmarkMethods#jit_enabled?.

require 'bundler/setup'
require 'mb-util'

puts MB::U.jit_enabled?
