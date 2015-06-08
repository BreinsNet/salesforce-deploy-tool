require 'aruba/cucumber'
require 'filewatcher'
require 'git'

# Necesary environment variables:
ENV["SFDT_GIT_REPO"] = File.join(Dir.pwd,'features/resources/repo')
ENV["SFDT_GIT_DIR"] = 'repo'
ENV["SFDT_SRC_DIR"] = 'salesforce/src'
ENV["SFDT_USERNAME"] = 'john.doe@example.com'
ENV["SFDT_PASSWORD"] = 'mysecurepass'
ENV["SFDT_SANDBOX"] = 'testEnv'

# Create a temprary home directory:
new_home = File.join(Dir.pwd,'tmp','home') 
ENV["HOME"] = new_home
FileUtils.rm_rf new_home if Dir.exists? new_home
FileUtils.mkdir new_home

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

# Before push and pull clone the repository
Before '@push,@pull' do 
  uri = ENV['SFDT_GIT_REPO']
  name = File.join 'tmp', 'aruba', ENV['SFDT_GIT_DIR']
  Git.clone(uri, name)
end

at_exit do
  FileUtils.rm 'bin/ant' if File.exists? 'bin/ant'
end
