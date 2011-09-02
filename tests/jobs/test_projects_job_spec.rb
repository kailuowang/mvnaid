require File.join File.dirname(__FILE__), %w(.. mock_command_runner)
require File.join File.dirname(__FILE__), %w(.. .. lib jobs test_projects_job)

describe TestProjectsJob do
  describe "run" do
    it "should build all projects that are being dependent by someone and test the rest" do
      project1 = Project.new(:p1, nil)
      project2 = Project.new(:p2, nil)
      project1.dependencies << project2
      test_projects_job = TestProjectsJob.new([project2], ProjectRepo.new(projects: [project1, project2]), nil)
      test_projects_job.should_receive(:build).with(project2)
      test_projects_job.should_not_receive(:build).with(project1)
      test_projects_job.should_receive(:test).with(project1)
      test_projects_job.run
    end

    it "should only test projects when all_dependents is false in option" do
      project1 = Project.new(:p1, nil)
      project2 = Project.new(:p2, nil)
      project1.dependencies << project2
      test_projects_job = TestProjectsJob.new([project2], ProjectRepo.new(projects: [project1, project2]), nil)
      test_projects_job.should_receive(:build).with(project2)
      test_projects_job.should_not_receive(:build).with(project1)
      test_projects_job.should_not_receive(:test).with(project1)
      test_projects_job.run(all_dependents: false)
    end

  end

  describe "projects_to_test" do
    it "should get all project that is dependent on the given projects" do
      project1,project2,project3,project4 = Project.new(:p1,nil), Project.new(:p2,nil), Project.new(:p3,nil), Project.new(:p4,nil)
      project3.dependencies << project1
      project4.dependencies << project2
      project_repo = ProjectRepo.new(projects: [project1, project2, project3, project4])
      TestProjectsJob.new([project1,project2], project_repo, nil).
                projects_to_test.should == [project1,project2,project3,project4]
    end
  end
end