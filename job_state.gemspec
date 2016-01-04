$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "job_state/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "job_state"
  s.version     = JobState::VERSION
  s.authors     = ["Wyatt Greene", "Ian McLean"]
  s.summary     = "This engine provides a way to poll resque jobs for their status and display to the user."


  s.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.rdoc"]
  s.test_files = Dir["test/**/*"]

  s.add_dependency "rails", ">= 3.2.19", "< 4.1.0"
  s.add_dependency "resque-status", '~>0.4.1'

end
