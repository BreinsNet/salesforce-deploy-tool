require 'aruba/cucumber'
require 'filewatcher'
require 'git'


# Create a temprary home directory:
new_home = File.join(Dir.pwd,'tmp','home') 
ENV["HOME"] = new_home
FileUtils.rm_rf new_home if Dir.exists? new_home
FileUtils.mkdir new_home

# Set a temporary dir to inspect build.xml
ENV["SFDT_TMP_DIR"] = '/tmp/sfdt-test'

# Cucumber / aruba configuration parameters
Before do
  @aruba_timeout_seconds = 300
  # Use mock ant
  FileUtils.cp "features/resources/mock/ant","bin/ant"
end

# Remove current configurations only once
Before '@config' do
  FileUtils.rm_rf File.join(File.expand_path('~/'),'.sf')
end

Before '@push,@pull,@config' do 

  # Necesary environment variables:
  ENV["SFDT_GIT_REPO"] = File.join(Dir.pwd,'features/resources/repo')
  ENV["SFDT_GIT_DIR"] = 'repo'
  ENV["SFDT_SRC_DIR"] = 'salesforce/src'
  ENV["SFDT_USERNAME"] = 'john.doe@example.com'
  ENV["SFDT_PASSWORD"] = 'mysecurepass'
  ENV["SFDT_SANDBOX"] = 'testEnv'

  # Clone repository
  uri = ENV['SFDT_GIT_REPO']
  name = File.join 'tmp', 'aruba', ENV['SFDT_GIT_DIR']
  Git.clone(uri, name)

  # Simulate a different ant library
  FileUtils.mkdir File.join 'tmp','aruba','lib'
  FileUtils.touch File.join 'tmp','aruba','lib','ant34.jar'
end

at_exit do
  FileUtils.rm 'bin/ant' if File.exists? 'bin/ant'
end

After do |s| 
  Cucumber.wants_to_quit = true if s.failed?
end
