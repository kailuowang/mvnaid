require File.join File.dirname(__FILE__), %w(.. .. lib deployers presentation_deployer)
require File.join File.dirname(__FILE__), %w(.. .. lib vcs_adaptors cvs_adaptor)
require File.join File.dirname(__FILE__), "..", "describe_internally"

describe PresentationDeployer do

  describe "remote_update" do
    it "should run remote update" do
      project = Project.new("proj1", "dir")
      cvs_adaptor = CvsAdaptor.new(nil)
      project.vcs_adaptor = cvs_adaptor
      deployer = PresentationDeployer.new(project: project,
                                        destination_path: "dir_on_server",
                                        server: "server",
                                        destination_username: "username")
      command_runner = deployer.instance_variable_get :@remote_command_runner
      command_runner.server.should == "server"
      command_runner.user.should == "username"
      command_runner.should_receive(:run).with("cd dir_on_server && #{cvs_adaptor.update_command}", {in_background: true})
      deployer.remote_update
    end

    it "should remotely run post update command if it's specified" do
      project = Project.new("proj1", "dir")
      cvs_adaptor = CvsAdaptor.new(nil)
      project.vcs_adaptor = cvs_adaptor
      deployer = PresentationDeployer.new(project: project,
                                            destination_path: "dir_on_server",
                                            server: "server",
                                            remote_post_update_command: "somescript.sh")
      command_runner = deployer.instance_variable_get :@remote_command_runner
      command_runner.should_receive(:run).with("cd dir_on_server && #{cvs_adaptor.update_command} && somescript.sh", {in_background: true})
      deployer.remote_update
    end
  end

  describe "remote_clean" do
    it "should find out the changes on the remote server"  do
      project = Project.new("proj1", "dir")
      cvs_adaptor = CvsAdaptor.new(nil)
      project.vcs_adaptor = cvs_adaptor
      deployer = PresentationDeployer.new(project: project,
                                            destination_path: "dir_on_server",
                                            server: "server")
      command_runner = deployer.instance_variable_get :@remote_command_runner
      cvs_adaptor.should_receive(:get_local_changes).with("dir_on_server", command_runner).and_return({});
      deployer.stub!(:remote_update)
      deployer.remote_clean
    end

    it "should remove all remotely changed files on the remote server and then remote update"  do
      project = Project.new("proj1", "dir")
      cvs_adaptor = CvsAdaptor.new(nil)
      project.vcs_adaptor = cvs_adaptor
      deployer = PresentationDeployer.new(project: project,
                                            destination_path: "dir_on_server",
                                            server: "server")
      cvs_adaptor.stub!(:get_local_changes).
              and_return({"file1.txt"=> false, "file2.txt" => false, "file3.txt" => true});
      deployer.should_receive(:remove_remote_file).with("file1.txt")
      deployer.should_receive(:remove_remote_file).with("file2.txt")
      deployer.should_receive(:remote_update)
      deployer.remote_clean
    end
  end

  describe "deploy" do
    it "should get local changes and copy them to destination and return false as restart_needed" do
      project = Project.new("proj1", "dir")
      project.should_receive(:get_local_changed_files).and_return(["file1", "file2"])
      command_runner = Object.new
      deployer = PresentationDeployer.new(project: project,
                                          destination_path: "destination",
                                          server: "server",
                                          command_runner: command_runner,
                                          destination_username: "username")
      mock_action = mock(:scp_action)
      mock_action.should_receive(:act).exactly(2)
      deployer.should_receive(:scp_action).with("file1").and_return(mock_action)
      deployer.should_receive(:scp_action).with("file2").and_return(mock_action)
      deployer.deploy().should == false
    end
  end
end

describe_internally PresentationDeployer do
  describe "scp_action" do
    it "should create ScpAction" do
      project = Project.new("proj1", "dir")
      command_runner = Object.new
      action = PresentationDeployer.new(project: project,
                                        destination_path: "destination",
                                        server: "server",
                                        command_runner: command_runner,
                                        destination_username: "username").scp_action("file")
      action.settings[:source].should == "file"
      action.settings[:directory].should == "dir"
      action.settings[:destination_path].should == "destination"
      action.settings[:server].should == "server"
      action.settings[:command_runner].should == command_runner
      action.settings[:username].should == "username"
    end
  end
  describe "remove_remote_file" do
     it "should run remote command to remove the file" do
       project = Project.new("proj1", "dir")
       deployer = PresentationDeployer.new(project: project, destination_path: "dir_on_server")
       command_runner = deployer.instance_variable_get :@remote_command_runner
       command_runner.should_receive(:run).with("cd dir_on_server && rm file2.txt", {})
       deployer.remove_remote_file("file2.txt")
     end
   end

end