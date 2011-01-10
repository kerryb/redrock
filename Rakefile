require "rubygems"
require "rake/gempackagetask"
require "rake/rdoctask"
require "rake/clean"
require "rspec/core/rake_task"

CLOBBER.include "redrock-*.gem"

RSpec::Core::RakeTask.new do |t|
  t.rspec_opts = %w{--format Fuubar --colour}
end

task :default => %w{compatibility package}

task :compatibility do
  results = {}
  versions = %x{gem list -ra webmock}.match(/\((.*)\)/)[1].split(", ")
  versions.each do |version|
    $stderr.puts "Testing against webmock #{version}..."
    results[version] = system "export WEBMOCK_VERSION=#{version};bundle;bundle exec rake spec"
  end
  $stderr.puts "Compatibility results:"
  results.keys.sort.each do |version|
    $stderr.puts "  webmock #{version}:\t#{results[version]}"
  end
end

task :package do
  %x{gem build redrock.gemspec}
end

Rake::RDocTask.new do |rd|
  rd.rdoc_files.include %w(*.rdoc lib/**)
  rd.rdoc_dir = "rdoc"
end
