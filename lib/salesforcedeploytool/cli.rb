
module SalesforceDeployTool

  class CLI

    include Commander::Methods

    def run config

      # Normalize file paths:
      config[:git_dir] = File.expand_path config[:git_dir]
      full_src_dir = File.join(config[:git_dir],config[:src_dir])

      # If the repository is not cloned then fail:
      if !File.exists?(full_src_dir) && ['pull','push'].include?(ARGV[0]) && !File.exists?(File.join(full_src_dir,"package.xml"))
        abort "ERROR: The source directory #{full_src_dir} is not a valid salesforce source directory"
      end

      # Chdir to working directory
      Dir.chdir config[:tmp_dir]

      # saleforce-deploy-tool version and description
      program :version, SalesforceDeployTool::VERSION
      program :description, 'A cli tool to help manage and deploy salesforce sandboxes with git'

      # Commands:
      command :pull do |c|
        c.syntax = 'sf pull'
        c.summary = 'Pull code from the sandbox'
        c.description = "Pull code from sandbox and update #{config[:git_dir]}"
        c.example 'usage:', 'sf pull'
        c.option "--append", "Pull code appending it to the local repository"
        c.option "--debug", "Verbose output"
        c.option "--sandbox NAME", "-s NAME", "use 'prod' to deploy production or sandbox name"
        c.action do |args, options|

          # short flag mapping
          options.sandbox = options.s if options.s

          # Parameter validation:
          if options.sandbox.nil? and config[:sandbox].nil?
            puts "error: please specify sandbox using --sandbox or sf sandbox"
            exit 1
          end
          config[:sandbox] = options.sandbox if options.sandbox
          config[:debug] = options.debug.nil? ? false : true

          # The salesforce URL
          config[:salesforce_url] = 
            ENV["SFDT_SALESFORCE_URL"] ||                                                                   # First from environment variables
            config[:salesforce_url]    ||                                                                   # Second from the configuration files
            ( config[:sandbox] == 'prod' ? 'https://login.salesforce.com' : 'https://test.salesforce.com' ) # If not defined anywhere, use defaults

          # Initialize
          sfdt = SalesforceDeployTool::App.new config

          # Clean all files from repo
          sfdt.clean_git_dir unless options.append

          # Pull the changes
          print "INFO: Pulling changes from #{config[:sandbox]} using url #{config[:salesforce_url]}  "
          print "\n\n" if options.debug
          sfdt.pull
          sfdt.clean_version

        end

      end

      command :push do |c|
        c.syntax = 'sf push [options]'
        c.summary = 'Push code into a sandbox'
        c.description = ''
        c.example 'description', "Push the code that is located into #{config[:git_dir]} into the active sandbox"
        c.option "--sandbox NAME", "-s NAME", "use 'prod' to deploy production or sandbox name"
        c.option "--debug", "Verbose output"
        c.option "--exclude CSV_LIST", "-x CSV_LIST", "a CSV list of metadata to exclude when creating destructiveChange.xml"
        c.option "--append", "Disable destructive change and do an append deploy"
        c.option "--build_number NUMBER","Record build number on version file"
        c.option "--run-all-tests", "-T", "Deploy and test"
        c.option "--run-tests CSV_LIST", "-r CSV_LIST", "a CSV list of individual classes to run tests"
        c.option "--check-only", "-c", "Check only, don't deploy"
        c.option "--include CSV_LIST", "-i CSV_LIST", "A CSV list of metadata type to include when creating destructiveChange.xml"
        c.action do |args, options|

          # short flag mapping
          options.check_only = true if options.c
          options.run_all_tests = true if options.T
          options.run_tests = options.r if options.r
          options.exclude = options.x if options.x
          options.sandbox = options.s if options.s
          options.include = options.i if options.i

          # Parameter validation:
          if options.run_all_tests and options.run_tests
            puts "warning: --run-tests is ignored as --test has been declared "
          end

          if options.sandbox.nil? and config[:sandbox].nil?
            puts "error: please specify the sandbox to pull from using --sandbox"
            exit 1
          end
          config[:sandbox] = options.sandbox if options.sandbox
          config[:debug] = options.debug.nil? ? false : true

          # The salesforce URL
          config[:salesforce_url] = 
            ENV["SFDT_SALESFORCE_URL"] ||                                                                   # First from environment variables
            config[:salesforce_url]    ||                                                                   # Second from the configuration files
            ( config[:sandbox] == 'prod' ? 'https://login.salesforce.com' : 'https://test.salesforce.com' ) # If not defined anywhere, use defaults

          # Initialize
          sfdt = SalesforceDeployTool::App.new config

          # Remove destructive change if there is one
          destructive_change_file = File.join(full_src_dir,'destructiveChanges.xml')
          FileUtils.rm destructive_change_file if File.exists? destructive_change_file

          if ! options.append
            # Pull changes from sandbox to temporary directory:
            config_tmp = config.clone
            config_tmp[:git_dir] = File.join(config[:tmp_dir],'repo_copy')
            FileUtils.cp_r config[:git_dir],config_tmp[:git_dir]
            sfdt_tmp = SalesforceDeployTool::App.new config_tmp
            sfdt_tmp.clean_git_dir
            print "INFO: Pulling changes from #{config[:sandbox]} using url #{config[:salesforce_url]} to temporary directory to generate destructiveChanges.xml  "
            print( options.debug.nil? ? "" : "\n\n" )
            sfdt_tmp.pull

            # Create destructiveChanges.xml
            puts "INFO: Creating destructive changes xml"
            dc_gen = Dcgen::App.new
            dc_gen.master = full_src_dir
            dc_gen.destination = File.join(config_tmp[:git_dir],config_tmp[:src_dir])
            dc_gen.output = destructive_change_file
            dc_gen.exclude = options.exclude.split(',') unless options.exclude.nil?
            dc_gen.include = options.include.split(',') unless options.include.nil?
            dc_gen.verbose = false if not options.debug
            dc_gen.generate_destructive_changes

          end

          # Push code to sandbox
          begin
            # Set version
            sfdt.build_number = options.build_number if not options.build_number.nil?
            sfdt.set_version

            # Enable test if option enabled
            sfdt.run_all_tests = options.run_all_tests.nil? ? false : true
            sfdt.run_tests = options.run_tests.split(',') unless options.run_tests.nil?

            # Check only option:
            sfdt.check_only = options.check_only

            # Push
            print( options.run_all_tests.nil? && options.run_tests.nil? ? "INFO: Deploying code to #{config[:sandbox]}:   ": "INFO: Deploying and Testing code to #{config[:sandbox]}:  " )
            print( options.debug.nil? ? "" : "\n\n" )
            sfdt.push
          ensure
            sfdt.clean_version
          end

        end
      end

      command :sandbox do |c|
        c.syntax = 'sf sandbox SANDBOX_NAME'
        c.summary = 'Set sandbox to work on, this can be overriden by --sandbox '
        c.description = 'Set the sandbox to work with pull and push. If no parameter defined, it will print the current sandbox selected.'
        c.action do |args, options|

          if args.size > 1
            puts "error: Wrong number of arguments"
          end

          if args.size == 0
            if ! config[:sandbox].nil?
              puts "sandbox: " + config[:sandbox]
              exit 0
            else
              puts "WARN: Sandbox has not been set yet"
              exit 1
            end
          end
          File.open(File.expand_path(SANDBOX_CONFIG_FILE),'w').write args.first

        end
      end

      command :config do |c|
        c.syntax = 'sf config'
        c.summary = 'Go through the configuration wizard to config your environment'
        c.action do |args, options|

          if args.size != 0
            puts "error: Wrong number of arguments"
          end

          config_new = {}

          config_new[:username] = ask "Please enter your SalesForce production login user name" do |q|
            q.validate = /^\S+@\S+$/ 
          end.to_s

          config_new[:password] = ask "Please enter your Salesforce production password" do |q|
            q.echo = "x"
          end.to_s

          git_name = ask "Please enter your Full name to be used as commit owner on GIT" do |q|
            q.validate = /^[a-zA-Z\s]+$/ 
          end

          git_email = ask "Please enter your email to be used as commit email on GIT" do |q|
            q.validate = /^\S+@\S+$/ 
          end

          config[:sandbox] = ask "Please enter your sandbox so to be used as default when push and pull" do |q|
            q.validate = /^[a-zA-Z]+$/ 
          end

          %x[git config --global user.email "#{git_email}"]
          %x[git config --global user.name "#{git_name}"]

          config[:username] = config_new[:username]
          config[:password] = config_new[:password]

          File.open(File.expand_path(SANDBOX_CONFIG_FILE),'w').write config[:sandbox]
          File.open(File.expand_path(CONFIG_FILE),'w').write config_new.to_yaml

          # Initialize
          sfdt = SalesforceDeployTool::App.new config

          # Clone
          sfdt.clone

        end
      end

      default_command :help

      run!

    end

  end

end


