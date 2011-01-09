require "rubygems"
require "rake/gempackagetask"
require "rake/rdoctask"
require "rake/clean"
require "rspec/core/rake_task"

CLOBBER.include "redrock-*.gem"

RSpec::Core::RakeTask.new do |t|
  t.rspec_opts = %w{--format Fuubar --colour}
end

task :default => %w{spec package}

task :package do
  %x{gem build redrock.gemspec}
end

Rake::RDocTask.new do |rd|
  rd.rdoc_files.include %w(*.rdoc lib/**)
  rd.rdoc_dir = "rdoc"
end
