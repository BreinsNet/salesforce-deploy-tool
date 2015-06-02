When /^I delete the repository directory/ do
  FileUtils.rm_rf File.join 'tmp', 'aruba', ENV['SFDT_GIT_DIR']
end

When /^I watch "(.+)" for changes and copy to "(.+)"$/ do |file,dest|
  file = File.join(Dir.pwd,'tmp','aruba',file)
  dest = File.join(Dir.pwd,'tmp','aruba',dest)
  fork do
    FileWatcher.new(file).watch do |filename|
      FileUtils.cp file, dest
      exit
    end
  end
end
