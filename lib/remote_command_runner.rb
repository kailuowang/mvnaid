class RemoteCommandRunner
  attr_reader :command_runner
  attr_reader :server
  attr_reader :user
  @@log_file_counter = 0
  def initialize(command_runner, server, user)
    @command_runner = command_runner
    @server = server
    @user = user
  end

  def run command, options={}
    if (options[:in_background])
      log_file_name = generate_log_file_name
      command = "(#{command}) <&- >>#{log_file_name} 2>&1 & disown"
      @command_runner.message_displayer.important {"running the following remotely in background. To see output run \"ssh #{@user}@#{@server} 'tail -f #{log_file_name}'\""}
    end
    command =  "ssh #{@user}@#{@server} \". ./.profile; #{command}\""
    @command_runner.run(command, options)
  end

  private
  def generate_log_file_name
    @@log_file_counter += 1
    "background_run_output_#{@@log_file_counter}.log"
  end
end