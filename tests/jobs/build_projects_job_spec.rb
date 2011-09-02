require File.join File.dirname(__FILE__), %w(.. .. lib jobs build_projects_job)
require File.join File.dirname(__FILE__), %w(.. mock_command_runner)
require "set"

describe BuildProjectsJob do
  describe "run" do
    it "should persist build time" do
     log_file = "buildlogtest.yml"
     modification_status_checker = Object.new
     modification_status_checker.stub!(:get_last_change).and_return(Time.now - 1)
     file_system = mock(:file_system)
     file_system.stub!(:exists?).and_return(true)
     project_repo = ProjectRepo.new(project_directories: {"test"=>""},
                                     build_log_file_path: log_file,
                                     modification_status_checker: modification_status_checker,
                                     file_system: file_system)
     build_projects_job = BuildProjectsJob.new(["test"], project_repo, MockCommandRunner.new)
     build_projects_job.run()
     project_repo = ProjectRepo.new(project_directories: {"test"=>""}, build_log_file_path: log_file)
     (Time.now - project_repo.get("test").build_time).should <= 0.1
     File.delete(log_file)
    end

    it "should only build build_pending projects unless explicitly asked to" do
      project_pending_build = Project.new("project pending build", "")
      project_pending_build.stub!(:build_pending?).and_return(true)
      project_not_pending_build = Project.new("project not pending build", "")
      project_not_pending_build.stub!(:build_pending?).and_return(false)
      project_pending_build.dependencies << project_not_pending_build
      project_repo = ProjectRepo.new(projects: [project_pending_build, project_not_pending_build])

      mock_action = mock("action")
      mock_action.should_receive(:act).exactly(3)
      build_projects_job = BuildProjectsJob.new([project_pending_build.name], project_repo, MockCommandRunner.new)
      build_projects_job.stub!(:build_action).with(project_pending_build).and_return(mock_action)
      build_projects_job.run()


      build_projects_job = BuildProjectsJob.new([project_pending_build.name, project_not_pending_build.name],
                                                 project_repo, MockCommandRunner.new)
      build_projects_job.stub!(:build_action).with(project_pending_build).and_return(mock_action)
      build_projects_job.stub!(:build_action).with(project_not_pending_build).and_return(mock_action)
      build_projects_job.run()
    end
  end
  
  describe "get_all_related_projects" do
    it "should work" do
      project1 = Project.new("1",nil)
      project2 = Project.new("2",nil)
      project3 = Project.new("3",nil)
      project4 = Project.new("4",nil)
      project5 = Project.new("5",nil)
      project1.dependencies << project3
      project3.dependencies << project4
      project4.dependencies << project5
      project1.dependencies << project2
      project2.dependencies << project3
      build_projects_job = BuildProjectsJob.new([project1, project2],nil, nil)
      build_projects_job.get_all_related_projects([project1, project2]).should ==
              [project5,project4,project3,project2,project1]
    end
  end

  describe "initialize" do
    it "should get projects from either list of projects names" do
      project1 = Project.new("1",nil)
      project2 = Project.new("2",nil)
      project_repo = ProjectRepo.new(projects: [project1, project2])
      BuildProjectsJob.new([project1.name, project2.name], project_repo,nil).projects.should == [project1, project2]
    end
    it "should get projects from either list of projects" do
      project1 = Project.new("1",nil)
      project2 = Project.new("2",nil)
      project_repo = ProjectRepo.new(projects: [project1, project2])
      BuildProjectsJob.new([project1, project2], project_repo, nil).projects.should == [project1, project2]
     end
  end
end