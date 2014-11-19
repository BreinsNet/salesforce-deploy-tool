
class Pinwheel 

  def initialize
    @pinwheel = %w{| / - \\}
  end

  def spin_it
    print "\b" + @pinwheel.rotate!.first
  end

  def clean
    print "\b"
  end

end


def myexec cmd, opts = {}
  
  opts[:stderr] = false if opts[:stderr].nil?
  opts[:stdout] = false if opts[:stdout].nil?
  opts[:exit_on_error] = true if opts[:exit_on_error].nil?
  opts[:timeout] = 600 if opts[:timeout].nil?
  opts[:spinner] = true if opts[:spinner].nil?
  opts[:message] = false if opts[:message].nil?
  opts[:okmsg] = false if opts[:okmsg].nil?
  opts[:failmsg] = false if opts[:failmsg].nil?
  logger = opts[:logger].nil? ? false : opts[:logger]

  command = File.basename($0)
  exit_status = 0
  start = Time.new
  pinwheel = Pinwheel.new if opts[:spinner]

  # Print header message
  print opts[:message] if opts[:message]

  stdout_all = ""
  stderr_all = ""
  begin 
    stdin,stdout,stderr,wait_thr = Open3.popen3(cmd)
    pid = wait_thr.pid
    # This block uses kernel.select to monitor if there is data on stdout IO 
    # object every 1 second. Then we use a nonblocking read ... so the whole 
    # idea is: Check if there is stdin to read, in 1 second unblock and 
    # try to read. Loop every 1 second over and over the same process until 
    # the process finishes or timeout is reached.
    elapsed = 0
    while wait_thr.status and (elapsed = Time.now - start) < opts[:timeout]
      Kernel.select([stdout,stderr],nil,nil,1)

      # Read STDIN in a nonblock way.
      begin
        stdout_line = stdout.read_nonblock(100) 
        print stdout_line if opts[:stdout]
        stdout_all += stdout_line
        # spin the pinwheel
        pinwheel.spin_it if opts[:spinner]
      rescue IO::WaitReadable
        # Exception raised when there is nothing to read
      rescue EOFError
        # Exception raised EOF is reached
        break
      end

      # Read STDERR in a nonblock way.
      begin
        stderr_line = stderr.read_nonblock(100) 
        print stderr_line if opts[:stderr]
        stderr_all += stderr_line
        # spin the pinwheel
        pinwheel.spin_it if opts[:spinner]
      rescue IO::WaitReadable
        # Exception raised when there is nothing to read
      rescue EOFError
        # Exception raised EOF is reached
        break
      end

    end

    # Log stdout output
    logger.info "\n" + stdout_all if logger and ! stdout_all.empty?
    logger.error "\n" + stderr_all if logger and ! stderr_all.empty?

    if elapsed > opts[:timeout]
      # We need to kill the process 
      Process.kill("KILL", pid)
      timeout_error_message = "Timeout #{opts[:timeout]} exceeded for #{cmd}"
      logger.error timeout_error_message if logger
      raise timeout_error_message
    end

    # Clean the pinwheel
    pinwheel.clean if opts[:spinner]

    # Handle the exit status:
    exit_status = wait_thr.value.exitstatus

    # Print fail or ok message
    if exit_status == 0
      puts opts[:okmsg] if opts[:okmsg]
    else
      puts opts[:failmsg] if opts[:failmsg]
    end

    # Exit on error
    if exit_status > 0
      $stderr.puts "#{command} error: Command returned non zero - error was:\n#{stderr_all}" if opts[:stderr]
      exit 1 if opts[:exit_on_error]
    end

  rescue => e
    $stderr.puts "\n#{command} error: Command failed, error was:\n#{e}".red
    exit 1 if opts[:exit_on_error]
    exit_status = 127
  end

  exit_status

end
