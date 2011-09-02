require File.join File.dirname(__FILE__), %w(.. .. lib jobs scp_action)

describe ScpAction do
  describe "act" do
     it "should run scp with correct parameter" do
       command_runner = mock(:command_runner)
       command_runner.should_receive(:run).
               with('cd directory && scp "source" "username@server:/destination_dir/source"', {})
       ScpAction.new(command_runner: command_runner,
                      source: "source",
                      directory: "directory",
                      destination_path: "destination_dir",
                      server: "server",
                      username: "username" ).act
     end
     it "should run scp with ~ in remote path" do
       command_runner = mock(:command_runner)
       command_runner.should_receive(:run).
               with('cd directory && scp "source" "auser@server:/home/auser/destination_dir/source"', {})
       ScpAction.new(command_runner: command_runner,
                      source: "source",
                      directory: "directory",
                      destination_path: "~/destination_dir",
                      server: "server",
                      username: "auser" ).act
     end
  end
end