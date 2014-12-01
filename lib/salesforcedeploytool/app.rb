module SalesforceDeployTool

  class App

    def initialize config

      @git_repo = config[:git_repo]
      @git_dir = config[:git_dir]
      @sandbox = config[:sandbox]
      @username = @sandbox == 'prod' ? config[:username] : config[:username] + '.' + @sandbox 
      @password = config[:password]
      @debug = config[:debug]
      @test = config[:test]
      @deploy_ignore_files = config[:deploy_ignore_files]

      @server_url = @sandbox == 'prod' ? 'https://login.salesforce.com' : 'https://test.salesforce.com'

      self.clone if ! Dir.exists? File.join(@git_dir,'.git')

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

      exit_code = myexec full_cmd, exec_options

      exit exit_code if exit_code != 0

    end

    def push

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

      Dir.chdir @git_dir

      # Delete files to be ignored:
      @deploy_ignore_files.each do |file|
        FileUtils.rm file if File.exists? file
      end

      exit_code = myexec full_cmd, exec_options

      exit exit_code if exit_code != 0

    end

  end

end
