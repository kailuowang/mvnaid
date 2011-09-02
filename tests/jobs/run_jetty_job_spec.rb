require File.join File.dirname(__FILE__), %w(.. .. lib jobs run_jetty_job)
require File.join File.dirname(__FILE__), %w(.. mock_command_runner)

describe RunJettyJob do
  describe "run" do
    it "should build all dependencies and run" do
      project1 = Project.new("1", nil)
      project2 = Project.new("2", nil)
      project3 = Project.new("3", nil)
      project1.dependencies << project2
      project2.stub!(:build_pending?).and_return(false)
      project2.dependencies << project3
      project3.stub!(:build_pending?).and_return(true)
      project_repo = ProjectRepo.new(projects: [project1, project2, project3])
      mock_run_jetty_action = mock("run_jetty_action")
      mock_run_jetty_action.should_receive(:act)
      mock_build_projects_job = mock("build_projects_job")
      mock_build_projects_job.should_receive(:run)
      run_jetty_job = RunJettyJob.new(project1.name, project_repo, MockCommandRunner.new)
      run_jetty_job.stub!(:build_projects_job).with([project2]).and_return(mock_build_projects_job)
      run_jetty_job.stub!(:run_jetty_action).with(project1).and_return(mock_run_jetty_action)
      run_jetty_job.run()
    end
  end
  describe "build_projects_job" do
    it "should create with projects and must_build_input_projects as false" do
      run_jetty_job = RunJettyJob.new("doesn't matter", nil, nil)
      project1 = Project.new("1", nil)
      project2 = Project.new("2", nil)
      build_projects_job = run_jetty_job.build_projects_job([project1, project2])
      build_projects_job.projects.should == [project1, project2]
      build_projects_job.must_build_input_projects.should == false
    end
  end
end