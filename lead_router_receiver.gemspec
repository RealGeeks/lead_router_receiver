$:.push File.expand_path("lib", __dir__)

# Maintain your gem's version:
require "lead_router_receiver/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "lead_router_receiver"
  s.version     = LeadRouterReceiver::VERSION
  s.authors     = ["Sam Livingston-Gray", "Chris Sass"]
  s.email       = ["sam@realgeeks.com", "chris@realgeeks.com"]
  s.homepage    = "https://github.com/RealGeeks/lead_router_receiver"
  s.summary     = "Rails Engine for receiving messages from the Lead Router firehose."
  s.description = "Rails Engine for receiving messages from the Lead Router firehose."
  s.license     = "MIT"

  s.metadata["allowed_push_host"] = "https://mKVpnyVa3n8U2PM98cnX@repo.fury.io/realgeeks/"

  s.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]
  s.test_files = Dir["spec/**/*"]

  s.add_dependency "rails", ">= 5.2", "< 7.0"

  s.add_development_dependency "sqlite3"
  s.add_development_dependency "rspec-rails"
  s.add_development_dependency "rspec-its"
  s.add_development_dependency "climate_control"
  s.add_development_dependency "awesome_print"
  s.add_development_dependency "table_print"
end
