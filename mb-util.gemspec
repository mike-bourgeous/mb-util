require_relative 'lib/mb/util/version'

Gem::Specification.new do |spec|
  spec.name          = "mb-util"
  spec.version       = MB::Util::VERSION
  spec.authors       = ["Mike Bourgeous"]
  spec.email         = ["mike@mikebourgeous.com"]

  spec.summary       = %q{Miscellaneous utility functions for personal projects.}
  spec.description   = %q{Use directly from Git for now, rather than rubygems.}
  spec.homepage      = "https://github.com/mike-bourgeous/mb-util"
  spec.required_ruby_version = Gem::Requirement.new(">= 2.7.1")

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency 'word_wrap'
  spec.add_development_dependency 'rake', '~> 13.0'
  spec.add_development_dependency 'pry'
  spec.add_development_dependency 'pry-doc'
  spec.add_development_dependency 'pry-byebug'
  spec.add_development_dependency 'coderay'

  spec.add_development_dependency 'rspec', '~> 3.10.0'
  spec.add_development_dependency 'simplecov', '~> 0.21.2'
end
