require File.join File.dirname(__FILE__), %w(.. lib remote_command_runner)
require File.join File.dirname(__FILE__), "describe_internally"

describe RemoteCommandRunner do
  describe "run" do
    it "should run correctly with ssh" do
      command_runner = CommandRunner.new
      options = {}
      command_runner.should_receive(:run).with("ssh user@server \". ./.profile; command\"", options)
      remote_command_runner = RemoteCommandRunner.new(command_runner, "server", "user")
      remote_command_runner.run("command", options)
    end
    it "should run in background" do
      command_runner = CommandRunner.new
      options = {in_background: true}
      remote_command_runner = RemoteCommandRunner.new(command_runner, "server", "user")
      remote_command_runner.should_receive(:generate_log_file_name).and_return "background_run_output.log"
      command_runner.should_receive(:run).with("ssh user@server \". ./.profile; (a command) <&- >>background_run_output.log 2>&1 & disown\"", options)
      remote_command_runner.run("a command", options)
    end
  end
end

describe_internally RemoteCommandRunner do
  describe "generate_log_file_name" do
    it "should generate a different log file name everytime" do
      names = Set.new
      10.times do
        remote_command_runner = RemoteCommandRunner.new(nil, nil, nil)
        names.add?(remote_command_runner.generate_log_file_name).should_not be nil
      end
    end
  end
end
