require File.join File.dirname(__FILE__), %w(.. .. lib deployers remote_deployer)

describe RemoteDeployer do
  describe "initialize" do
    it "should create remote command runner" do
      command_runner = mock(:command_runner)
      remote_deployer = RemoteDeployer.new(command_runner: command_runner,
                                            server: "sandbox",
                                            username: "wangk")
      remote_command_runner = remote_deployer.instance_variable_get(:@remote_command_runner)
      remote_command_runner.server.should == "sandbox"
      remote_command_runner.command_runner.should == command_runner
      remote_command_runner.user.should == "wangk"
    end
  end
  describe "remote_update" do
    it "should remote stop server and cd to direction and svn up and mvn clean install" do
      remote_deployer = RemoteDeployer.new( remote_location: "remote_dir",
                                            restart_script: "restart_script.sh")
      remote_command_runner = remote_deployer.instance_variable_get(:@remote_command_runner)
      remote_command_runner.should_receive(:run).with("restart_script.sh stop && cd remote_dir && svn up && mvn clean install", {in_background: true})
      remote_deployer.remote_update
    end
    it "should simply cd to direction and svn up and mvn clean install when no restart_script specified " do
      remote_deployer = RemoteDeployer.new( remote_location: "remote_dir")
      remote_command_runner = remote_deployer.instance_variable_get(:@remote_command_runner)
      remote_command_runner.should_receive(:run).with("cd remote_dir && svn up && mvn clean install", {in_background: true})
      remote_deployer.remote_update
    end

  end

  describe "deploy" do
    it "should do nothing and return false as server restart needed" do
      RemoteDeployer.new({}).deploy.should == false
    end
  end
end