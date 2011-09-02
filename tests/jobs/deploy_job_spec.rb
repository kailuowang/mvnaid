require File.join File.dirname(__FILE__), %w(.. .. lib jobs deploy_job)
require File.join File.dirname(__FILE__), %w(.. .. lib remote_command_runner)

describe DeployJob do
  describe "run" do
    it "should only deploy projects that are deploy_pending" do
      project1 = Project.new(:p1,nil)
      project1.should_receive(:deploy_pending?).and_return(true)
      project1.should_receive(:deploy)
      project2 = Project.new(:p2,nil)
      project2.should_receive(:deploy_pending?).and_return(false)
      project2.should_not_receive(:deploy)
      DeployJob.new(ProjectRepo.new(projects: [project1, project2]), nil).run
    end

    it "should scream if a project is not local and skip it" do
      project = Project.new(:p1,nil)
      project.should_receive(:local?).and_return(false)
      message_displayer = MessageDisplayer.new(false, false)
      message_displayer.should_receive(:scream).with{"Project #{project.name} is missing in local. Please check it out using build.rb --checkout "}
      DeployJob.new(ProjectRepo.new(projects: [project]), nil, message_displayer).run
    end

    it "should restart sandbox if any of the deploy is restart needed" do
      project1 = Project.new(:p1,nil)
      project1.should_receive(:deploy_pending?).and_return(true)
      project1.should_receive(:deploy).and_return(true)
      project2 = Project.new(:p2,nil)
      project2.should_receive(:deploy_pending?).and_return(true)
      project2.should_receive(:deploy).and_return(false)
      deploy_job = DeployJob.new(ProjectRepo.new(projects: [project1, project2]), nil)
      deploy_job.should_receive(:restart_sandbox)
      deploy_job.run
    end

    it "should not restart sandbox if none of the deploy is restart needed" do
      project1 = Project.new(:p1,nil)
      project1.should_receive(:deploy_pending?).and_return(true)
      project1.should_receive(:deploy).and_return(false)
      project2 = Project.new(:p2,nil)
      project2.should_receive(:deploy_pending?).and_return(true)
      project2.should_receive(:deploy).and_return(false)

      deploy_job = DeployJob.new(ProjectRepo.new(projects: [project1, project2]), nil)
      deploy_job.should_not_receive(:restart_sandbox)
      deploy_job.run
    end

    it "should not restart sandbox if no project are deployed" do
      project1 = Project.new(:p1,nil)
      project1.should_receive(:deploy_pending?).and_return(false)
      project2 = Project.new(:p2,nil)
      project2.should_receive(:deploy_pending?).and_return(false)
      deploy_job = DeployJob.new(ProjectRepo.new(projects: [project1, project2]), nil)
      deploy_job.should_not_receive(:restart_sandbox)
      deploy_job.run
    end

    it "should persist deploy time" do
      project1 = Project.new(:p1,nil)
      project1.should_receive(:deploy_pending?).and_return(true)
      project1.should_receive(:deploy)
      project_repo = ProjectRepo.new(projects: [project1])
      project_repo.should_receive(:persist_project_logs).at_least(1)
      DeployJob.new(project_repo, nil).run
    end
  end

  describe "initialize" do
    it "should create remote command runner if there is restart script and server set" do
      deploy_info = {username: "user1", server: "server", restart_script_path: "/home/wangk/restartTRUS.sh"}
      project_repo = ProjectRepo.new(project_deploy_info: {general: deploy_info})
      command_runner = mock(:command_runner)
      remote_command_runner = DeployJob.new(project_repo, command_runner).command_runner
      remote_command_runner.is_a?(RemoteCommandRunner).should == true
      remote_command_runner.command_runner.should == command_runner
      remote_command_runner.user.should == "user1"
      remote_command_runner.server.should == "server"
    end

    it "should user original command runner if there is no server set but only restart_script" do
      deploy_info = {username: "user1", restart_script_path: "/home/wangk/restartTRUS.sh"}
      project_repo = ProjectRepo.new(project_deploy_info: {general: deploy_info})
      command_runner = mock(:command_runner)
      DeployJob.new(project_repo, command_runner).command_runner.should eql command_runner
    end

  end

  describe "restart_sandbox" do
    it "should run corrrect command" do
      deploy_info = {username: "user1", server: "server", restart_script_path: "/home/wangk/restartTRUS.sh"}
      project_repo = ProjectRepo.new(project_deploy_info: {general: deploy_info})
      deploy_job = DeployJob.new(project_repo, nil)
      deploy_job.command_runner.should_receive(:run).with("/home/wangk/restartTRUS.sh")
      deploy_job.restart_sandbox
    end
  end
end
