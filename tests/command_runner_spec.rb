require File.join File.dirname(__FILE__), %w(.. lib command_runner)

describe CommandRunner do

  describe "run" do
    it "should do command silently by default" do
      command_runner = CommandRunner.new
      command_runner.should_receive(:do_command).with("command", false).and_return(["", true])
      command_runner.run("command")
    end
  end
end
