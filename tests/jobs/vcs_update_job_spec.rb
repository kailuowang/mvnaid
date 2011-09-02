require File.join File.dirname(__FILE__), %w(.. .. lib jobs vcs_update_job)
require File.join File.dirname(__FILE__), %w(.. .. lib jobs build_action)
require File.join File.dirname(__FILE__), %w(.. mock_command_runner)

describe VcsUpdateJob do
  describe "run" do
    it "should run svn update commands for each project in a dependency order" do
      command_runner = MockCommandRunner.new
      svn_adaptor = SvnAdaptor.new(command_runner)
      project1 = Project.new("1", "dir1", vcs_adaptor: svn_adaptor)
      project2 = Project.new("2", "dir2", vcs_adaptor: svn_adaptor)
      project3 = Project.new("3", "dir3", vcs_adaptor: svn_adaptor)
      project1.dependencies << project2
      project2.dependencies << project3
      project_repo = ProjectRepo.new(projects:[project2, project1, project3])
      VcsUpdateJob.new(project_repo, command_runner).run
      command_runner.commands_run.should == ["cd dir3 && svn up","cd dir2 && svn up", "cd dir1 && svn up" ]
    end

    it "should skip any non-local project" do
      project1 = Project.new(:local_project, :local_project_diretory, local: true)
      project2 = Project.new(:local_missing_project, :local_missing_project_diretory, local: false)
      project_repo = ProjectRepo.new(projects:[project2, project1])
      svn_update_job = VcsUpdateJob.new(project_repo, nil)
      svn_update_job.should_receive(:update).with(project1).and_return(true)
      svn_update_job.should_receive(:build).with(project1)
      svn_update_job.should_not_receive(:update).with(project2)
      svn_update_job.run()
    end

    it "should run build if svn update some files" do
      project1 = Project.new("svn_changed_project", "changed_proj_dir")
      project2 = Project.new("svn_not_changed_project", "no_change_proj_dir")
      project_repo = ProjectRepo.new(projects:[project2, project1])
      svn_update_job = VcsUpdateJob.new(project_repo, nil)
      svn_update_job.stub!(:update).with(project1).and_return(true)
      svn_update_job.stub!(:update).with(project2).and_return(false)
      svn_update_job.should_receive(:build).with(project1)
      svn_update_job.should_not_receive(:build).with(project2)
      svn_update_job.run()
    end
  end

  describe "build" do
    it "should use TestProjectsJob to build the project" do
      command_runner = mock("command")
      project_repo = mock("project_repo")
      project = Project.new("test","")
      project.stub!(:eligible_for_build?).and_return(true)
      test_projects_job = mock(:test_projects_job)
      TestProjectsJob.should_receive(:new).with( [project], project_repo, command_runner).and_return(test_projects_job)
      test_projects_job.should_receive(:run).with({all_dependents: false})
      svn_update_job = VcsUpdateJob.new(project_repo, command_runner)
      svn_update_job.build(project)
    end
  end


  describe "update" do
    it "should be able to tell either updated or not" do
      command_runner = mock("command_runner")
      command_runner.should_receive(:run).with("cd dir1 && svn up", anything()).and_return("U  dir1foo.txt  \nUpdated to revision 2. ")
      project = Project.new("1", "dir1", vcs_adaptor: SvnAdaptor.new(command_runner))
      VcsUpdateJob.new(nil, command_runner ).update(project).should == true
    end

    it "should remote update the project if its deployer has support for it" do
      command_runner = mock("command_runner")
      command_runner.stub(:run)
      project = Project.new("1", "dir1")
      deployer = mock(:deployer)
      deployer.should_receive(:respond_to?).with(:remote_update).and_return(true)
      deployer.should_receive(:remote_update)
      project.deployer = deployer
      project.should_receive(:vcs_update).and_return(true)
      VcsUpdateJob.new(nil, command_runner ).update(project)
    end
  end
end