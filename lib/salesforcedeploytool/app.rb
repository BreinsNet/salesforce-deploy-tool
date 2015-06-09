module SalesforceDeployTool

  class App

    attr_accessor :build_number
    attr_accessor :run_all_tests
    attr_accessor :check_only

    def initialize config
     
      # Config file validation:
      ( @git_repo = config[:git_repo] ).nil? and raise "Invalid Config: git_repo not found"
      ( @git_dir = config[:git_dir] ).nil? and raise "Invalid Config: git_dir not found"
      ( @src_dir = config[:src_dir] ).nil? and raise "Invalid Config: src_dir not found"
      ( @sandbox = config[:sandbox] ).nil? and raise "Invalid Config: sandbox not found"
      ( @username = config[:username] ).nil? and raise "Invalid Config: username not found, please run `sf config`"
      ( @password = config[:password] ).nil? and raise "Invalid Config: password not found, please run `sf config`"

      # Parameter Normalization
      @git_dir = File.expand_path(@git_dir)
      @full_src_dir = File.join(@git_dir,@src_dir)
      @version_file = File.join(@full_src_dir,config[:version_file]) if !config[:version_file].nil?
      @deploy_ignore_files = config[:deploy_ignore_files].map {|f| File.expand_path(File.join(@full_src_dir,f)) } if !config[:deploy_ignore_files].nil?
      @build_number_pattern = config[:build_number_pattern]
      @commit_hash_pattern = config[:commit_hash_pattern]
      @username = @sandbox == 'prod' ? @username : @username + '.' + @sandbox 
      @server_url = config[:salesforce_url]
      @libant = File.expand_path(config[:libant]) if config[:libant]

      # Defaults
      @check_only = false
      @run_tests = []
      @debug ||= config[:debug]
      @build_number ||= 'N/A'
      @version_file ||= false
      @build_number_pattern ||= false
      @commit_hash_pattern ||= false
      @deploy_ignore_files ||= []

      # Template dir
      buildxml_path = File.join($:.select {|x| x.match(/salesforce-deploy-tool/) },'..','tpl','build.xml.erb')
      @buildxml_erb = File.read(buildxml_path)


    end

    # @run_tests can't be nil
    def run_tests= value
      value ||= []
      raise "ArgumentError" if value.class != Array
      @run_tests = value 
    end

    def set_version

      g = Git.open(@git_dir)

      File.open(@version_file,'r+') do |file|
        content = file.read
        content.gsub!(/#{@build_number_pattern}/,@build_number) if @build_number_pattern
        content.gsub!(/#{@commit_hash_pattern}/,g.log.first.sha) if @commit_hash_pattern
        file.seek(0,IO::SEEK_SET)
        file.truncate 0
        file.write content
      end if @version_file && File.exists?(@version_file)

    end

    def clean_version

      g = Git.open(@git_dir)
      g.checkout @version_file if @version_file && File.exists?(@version_file)

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

    def clean_git_dir

      Dir[File.join(@full_src_dir,'*')].each do |dir|
        FileUtils.rm_rf dir unless dir =~ /.*package.xml$/
      end

    end

    def pull

      # Parameter validation
      raise "package.xml not found under #{@full_src_dir}" if !File.exists? File.join(@full_src_dir,'package.xml')

      renderer = ERB.new(@buildxml_erb, nil,'%<>-')
      File.open('build.xml','w') {|f| f.write renderer.result(binding) }

      env_vars = ""
      env_vars += " SF_SRC_DIR=" + @full_src_dir
      env_vars += " SF_USERNAME=" + @username
      env_vars += " SF_PASSWORD=" + @password
      env_vars += " SF_SERVERURL=" + @server_url
      cmd = " ant"
      cmd += " -lib #{@libant}" if @libant
      cmd += " retrieveCode"

      full_cmd = env_vars + cmd

      exec_options = {
        :stderr => @debug,
        :stdout => @debug,
        :spinner => ! @debug,
        :okmsg => "OK",
        :failmsg => "FAILED",
      }

      if @debug
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

      # Parameter validation
      raise "package.xml not found under #{@full_src_dir}" if !File.exists? File.join(@full_src_dir,'package.xml')

      renderer = ERB.new(@buildxml_erb, nil,'%<>-')
      File.open('build.xml','w') {|f| f.write renderer.result(binding) }

      # Set env variables to run ant
      env_vars = ""
      env_vars += " SF_SRC_DIR=" + @full_src_dir
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

      ant_cmd = " ant"
      ant_cmd += " -lib #{@libant}" if @libant
      if @run_all_tests  
        cmd = " deployAndTestCode" 
      else
        if ! @run_tests.empty?
          cmd = " deployAndRunSpecifiedTests"
        else
          cmd = " deployCode"
        end
      end

      if @check_only
        cmd = " checkOnlyCode"
      end
       
      full_cmd = env_vars + ant_cmd + cmd

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
