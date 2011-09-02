#!/usr/bin/env ruby
require_relative %w(lib jobs_runner)

JobsRunner.new(ARGV).run()
