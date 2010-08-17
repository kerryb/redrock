require "rubygems"
require "rake/gempackagetask"
require "rake/rdoctask"

require "spec"
require "spec/rake/spectask"
Spec::Rake::SpecTask.new do |t|
  t.spec_opts = %w(--format specdoc --colour)
  t.libs = ["spec"]
end

task :default => ["spec"]

spec = Gem::Specification.new do |s|

  # Change these as appropriate
  s.name              = "redrock"
  s.version           = "0.0.1"
  s.summary           = "Proxy for using WebMock remotely"
  s.author            = "Kerry Buckley"
  s.email             = "kerryjbuckley@gmail.com"
  s.homepage          = "http://github.com/kerryb/redrock"

  s.has_rdoc          = true
  s.extra_rdoc_files  = %w(README.rdoc)
  s.rdoc_options      = %w(--main README.rdoc)

  s.files             = Dir.glob("{spec/**,lib/**}")
  s.require_paths     = ["lib"]

  s.add_dependency "thin", "~> 1.0"

  s.add_development_dependency "rspec"
  s.add_development_dependency "curb"
end

Rake::GemPackageTask.new(spec) do |pkg|
  pkg.gem_spec = spec
end

desc "Build the gemspec file #{spec.name}.gemspec"
task :gemspec do
  file = File.dirname(__FILE__) + "/#{spec.name}.gemspec"
  File.open(file, "w") {|f| f << spec.to_ruby }
end

task :package => :gemspec

Rake::RDocTask.new do |rd|
  rd.rdoc_files.include "README.rdoc", "lib/**"
  rd.rdoc_dir = "rdoc"
end

desc 'Clear out RDoc and generated packages'
task :clean => [:clobber_rdoc, :clobber_package] do
  rm "#{spec.name}.gemspec"
end