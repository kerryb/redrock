$:.unshift File.expand_path("../../lib", __FILE__)
require "rubygems"
require "spec"
require "curb"
require "stringio"
require "redrock"
require "webmock/test_unit"
require "webmock/rspec"
include RedRock
