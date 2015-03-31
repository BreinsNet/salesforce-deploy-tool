config = YAML::load(File.open('cucumber-config.yaml'))

When /^I type my salesforce (.*)$/ do |input|
  raise "Please create credentials.yaml" if config[input.to_sym].nil? 
  type(config[input.to_sym])
end

When /^I delete the repository directory/ do
  FileUtils.rm_rf File.join 'tmp', 'aruba', ENV['SFDT_GIT_DIR']
end

When /^I watch "(.+)" for changes and copy to "(.+)"$/ do |file,dest|
  file = File.join('tmp','aruba',file)
  dest = File.join('tmp','aruba',dest)
  fork do
    FileWatcher.new(file).watch do |filename|
      FileUtils.cp file, dest
      exit
    end
  end
end

Transform /^.+$/ do |arg|
  case arg
  when String
    config[:replacement_patterns].keys.each do |key|
      arg = arg.gsub /#{key.to_s}/, config[:replacement_patterns][key]
    end
    config[:environment_variables].keys.each do |key|
      arg = arg.gsub /#{key.to_s}/, config[:environment_variables][key]
    end
  when Cucumber::Ast::Table
    arg.cell_matrix.each do |c| 
      config[:replacement_patterns].keys.each do |key|
        c[1].value = c[1].value.gsub /#{key.to_s}/, config[:replacement_patterns][key]
      end
      config[:environment_variables].keys.each do |key|
        c[1].value = c[1].value.gsub /#{key.to_s}/, config[:environment_variables][key]
      end
    end
  end

  arg

end

