$:.unshift File.expand_path("../../lib", __FILE__)
require "rubygems"
require "rspec"
require "curb"
require "stringio"
require "redrock"
require "webmock/test_unit"
require "webmock/rspec"
include RedRock
Dir[File.expand_path("../support/**/*.rb", __FILE__)].each do |f|
  require f
end
