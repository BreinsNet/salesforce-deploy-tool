When /^I type my salesforce (.*)$/ do |input|
  config = YAML::load(File.open('credentials.yaml'))
  raise "Please create credentials.yaml" if config[input.to_sym].nil? 
  type(config[input.to_sym])
end
