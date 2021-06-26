#!/usr/bin/env ruby

require 'bundler/setup'

require 'fileutils'

require 'mb-util'

begin
  puts "\n\n\e[1mSingle-file overwrite prompt\e[0m\n\n"
  MB::U.prevent_overwrite($0, prompt: true)
rescue => e
  puts "\nReceived exception #{MB::U.highlight(e)}\n\t#{e.backtrace.join("\n\t")}"
end

begin
  puts "\n\n\e[1mMultiple-file overwrite prompt\e[0m\n\n"
  MB::U.prevent_mass_overwrite($0, prompt: true, delete: false)
rescue => e
  puts "\nReceived exception #{MB::U.highlight(e)}\n\t#{e.backtrace.join("\n\t")}"
end
