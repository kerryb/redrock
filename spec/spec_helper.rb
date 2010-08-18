$:.unshift File.expand_path("../../lib", __FILE__)
require "spec"
require "curb"
require "stringio"
require "redrock"
include RedRock
require "webmock/test_unit"
require "webmock/rspec"
