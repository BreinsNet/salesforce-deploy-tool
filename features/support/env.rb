require 'aruba/cucumber'
require 'filewatcher'
require 'git'

# Load configuratiohn
config = YAML::load(File.open('config.yaml'))

# Cucumber / aruba configuration parameters
Before do
  @aruba_timeout_seconds = 300
end

# Set environment variables
Before do
  config[:environment_variables].keys.each do |key|
    ENV[key.to_s.upcase] = config[:environment_variables][key]
  end
end

# Before push and pull clone the repository
Before '@push,@pull' do 
  uri = ENV['SFDT_GIT_REPO']
  name = File.join 'tmp', 'aruba', ENV['SFDT_GIT_DIR']
  Git.clone(uri, name)
end
