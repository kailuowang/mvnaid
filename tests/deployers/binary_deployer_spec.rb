require File.join File.dirname(__FILE__), %w(.. .. lib deployers binary_deployer)
require File.join File.dirname(__FILE__), %w(.. .. lib util)
require File.join File.dirname(__FILE__), "..", "describe_internally"

describe BinaryDeployer do
  describe "deploy" do
    it "should build build_pending project and copy targets to destination and return true as restart_needed" do
      project = Project.new("proj1", "dir")
      project.should_receive(:build_pending?).and_return(true)
      deployer = BinaryDeployer.new(project: project)
      deployer.should_receive(:build)
      deployer.should_receive(:scp_binaries)
      deployer.deploy().should == true
    end

    it "should not build none build_pending project but still copy them and return true as restart_needed" do
      project = Project.new("proj1", "dir")
      project.should_receive(:build_pending?).and_return(false)
      deployer = BinaryDeployer.new(project: project)
      deployer.should_not_receive(:build)
      deployer.should_receive(:scp_binaries)
      deployer.deploy.should == true
    end

    it "should scp multiple jars if there are multiple jar path specified" do
      project = Project.new("proj1", "dir")
      project.should_receive(:build_pending?).and_return(true)
      deployer = BinaryDeployer.new(project: project, binary_file_path: ["path1", "path2"])
      mock_action = mock(:cp_action)
      mock_action.should_receive(:act).exactly(2)
      deployer.should_receive(:build)
      deployer.should_receive(:cp_action).with("path1").and_return(mock_action)
      deployer.should_receive(:cp_action).with("path2").and_return(mock_action)
      deployer.deploy
    end
  end
end


describe_internally BinaryDeployer do
  describe "cp_action" do
    it "should create ScpAction when server is set" do
      project = Project.new("proj1", "dir")
      command_runner = Object.new
      action = BinaryDeployer.new(project: project,
                                    destination_path: "destination/dir",
                                    server: "server",
                                    command_runner: command_runner,
                                    destination_username: "username").cp_action("~/.m2/target.jar")
      action.settings[:source].should == "target.jar"
      action.settings[:directory].should == "~/.m2"
      action.settings[:destination_path].should == "destination/dir"
      action.settings[:server].should == "server"
      action.settings[:command_runner].should == command_runner
      action.settings[:username].should == "username"
    end
    it "should create normal copy Action when server is not set" do
      project = Project.new("proj1", "dir")
      command_runner = Object.new
      action = BinaryDeployer.new(  project: project,
                                    destination_path: "destination/dir",
                                    command_runner: command_runner).cp_action("~/.m2/target.jar")
      command_runner.should_receive(:run).with("cd #{Util.path "~/.m2"} && cp target.jar #{"destination/dir"}", {})
      action.act
    end
  end
end