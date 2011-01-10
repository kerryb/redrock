# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name              = "redrock"
  s.version           = "0.1.2"
  s.summary           = "Proxy for using WebMock remotely"
  s.description       = "Use WebMock to test applications that aren't " +
                        "running in the same process as the tests"
  s.author            = "Kerry Buckley"
  s.email             = "kerryjbuckley@gmail.com"
  s.homepage          = "http://github.com/kerryb/redrock"

  s.has_rdoc          = true
  s.extra_rdoc_files  = Dir.glob("{*.rdoc}")
  s.rdoc_options      = %w(--main README.rdoc)

  s.files             = Dir.glob("{spec/**/*,lib/**/*}")
  s.require_paths     = ["lib"]

  s.add_dependency "json"
  s.add_dependency "thin"
  s.add_dependency "webmock", ENV["WEBMOCK_VERSION"] || "~> 1.3.0"

  s.add_development_dependency "curb"
  s.add_development_dependency "fuubar"
  s.add_development_dependency "rake"
  s.add_development_dependency "rspec", "~> 2.0"
end
