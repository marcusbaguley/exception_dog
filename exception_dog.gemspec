
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "exception_dog/version"

Gem::Specification.new do |spec|
  spec.name          = "exception_dog"
  spec.version       = ExceptionDog::VERSION
  spec.authors       = ["Marcus Baguley"]
  spec.email         = ["marcus.baguley@gmail.com"]

  spec.summary       = %q{Wrapper for sending exceptions to datadog as events}
  spec.description   = %q{Experiment to see if datadog can be used as an exception store}
  spec.homepage      = "https://github.com/marcusbaguley/exception_dog"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.16"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "minitest", "~> 5.0"
  spec.add_development_dependency "webmock"
end
