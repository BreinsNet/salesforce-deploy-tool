module SalesforceDeployTool

  class App

    attr_accessor :build_number
    attr_accessor :test

    def initialize config
     
      # Parameter Normalization
      config[:git_dir] = File.expand_path config[:git_dir]
      config[:tmp_dir] = File.expand_path config[:tmp_dir]
      config[:version_file] = File.expand_path config[:version_file]
      config[:deploy_ignore_files] = config[:deploy_ignore_files].map {|f| File.expand_path File.join(config[:git_dir],f)}

      # Defaults
      @debug = config[:debug]
      @test = config[:test]
      @build_number = 'N/A'

      # Config file validation:
      ( @git_repo = config[:git_repo] ).nil? and raise "Invalid Config: git_repo not found"
      ( @git_dir = config[:git_dir] ).nil? and raise "Invalid Config: git_dir not found"
      ( @sandbox = config[:sandbox] ).nil? and raise "Invalid Config: sandbox not found"
      ( @password = config[:password] ).nil? and raise "Invalid Config: password not found, please run `sf config`"
      ( @deploy_ignore_files = config[:deploy_ignore_files] ).nil? and raise "Invalid Config: deploy_ignore_files not found"
      ( @build_number_pattern = config[:build_number_pattern] ).nil? and raise "Invalid Config: build_number_pattern not found"
      ( @commit_hash_pattern = config[:commit_hash_pattern] ).nil? and raise "Invalid Config: commit_hash_pattern not found"
      ( @version_file = config[:version_file] ).nil? and raise "Invalid Config: version_file not found"

      

      config[:username].nil? and raise "Invalid Config: username not found, please run `sf config`"
      config[:password].nil? and raise "Invalid Config: password not found, please run `sf config`"

      @username = @sandbox == 'prod' ? config[:username] : config[:username] + '.' + @sandbox 
      @server_url = @sandbox == 'prod' ? 'https://login.salesforce.com' : 'https://test.salesforce.com'

    end

    def set_version

      g = Git.open(@git_dir)

      File.open(@version_file,'r+') do |file|
        content = file.read
        content.gsub!(/#{@build_number_pattern}/,@build_number)
        content.gsub!(/#{@commit_hash_pattern}/,g.log.first.sha)
        file.seek(0,IO::SEEK_SET)
        file.truncate 0
        file.write content
      end if File.exists? @version_file

    end

    def clean_version

      g = Git.open(@git_dir)
      g.checkout @version_file if File.exists? @version_file

    end

    def clone

      if Dir.exists? File.join(@git_dir,'.git')
        return
      end

      begin
        Git.clone(@git_repo, File.basename(@git_dir), :path => File.dirname(@git_dir))
      rescue => e
        STDERR.puts "ERROR: A problem occured when cloning #{@git_repo}, error was\n\n"
        puts e
        exit 1
      end

    end

    def clean_git_dir message = nil

      print message
      Dir[File.join(@git_dir,'src','*')].each do |dir|
        FileUtils.rm_rf dir unless dir =~ /.*package.xml$/
      end
      puts "OK" unless message.nil?

    end

    def pull message = nil

      env_vars = ""
      env_vars += " SF_USERNAME=" + @username
      env_vars += " SF_PASSWORD=" + @password
      env_vars += " SF_SERVERURL=" + @server_url
      cmd = " ant retrieveCode"

      full_cmd = env_vars + cmd

      Dir.chdir @git_dir

      exec_options = {
        :stderr => @debug,
        :stdout => @debug,
        :spinner => ! @debug,
        :message => message,
        :okmsg => "OK",
        :failmsg => "FAILED",
      }

      if @debug
        exec_options[:message] += "\n\n"
        exec_options[:okmsg] = nil
        exec_options[:failmsg] = nil
      end

      # Pull the code
      exit_code = myexec full_cmd, exec_options

      # Delete files to be ignored:
      @deploy_ignore_files.each do |file|
        FileUtils.rm file if File.exists? file
      end

      exit exit_code if exit_code != 0

    end

    def push

      # Working dir
      Dir.chdir @git_dir

      # Set env variables to run ant
      env_vars = ""
      env_vars += " SF_USERNAME=" + @username
      env_vars += " SF_PASSWORD=" + @password
      env_vars += " SF_SERVERURL=" + @server_url

      # myexec options
      exec_options = {
        :stderr   =>  @debug,
        :stdout   =>  @debug,
        :spinner  =>  ! @debug,
        :okmsg    =>  "OK",
        :failmsg  =>  "FAILED",
      }

      if @debug
        exec_options[:okmsg]    =   nil
        exec_options[:failmsg]  =   nil
      end

      # Deploy code
      exec_options[:message] = @test ?  "INFO: Deploying and Testing code to #{@sandbox}:  " : "INFO: Deploying code to #{@sandbox}:  "
      exec_options[:message]  +=  "\n\n" if @debug

      cmd = @test ? " ant deployAndTestCode" : " ant deployCode"
      full_cmd = env_vars + cmd

      # Delete files to be ignored:
      @deploy_ignore_files.each do |file|
        FileUtils.rm file if File.exists? file
      end

      # Push the code
      exit_code = myexec full_cmd, exec_options

      # exit with exit_code
      exit exit_code if exit_code != 0

    end

  end

end
