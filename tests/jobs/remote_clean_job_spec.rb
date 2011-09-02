require File.join File.dirname(__FILE__), %w(.. .. lib jobs remote_clean_job)

describe RemoteCleanJob do
  describe "run" do
    it "should to run remote_clean on every projects' deployer" do
      project1 = Project.new(:p1, "")
      project1.deployer = mock(:PresentationDeployer)
      project1.deployer.should_receive(:remote_clean)
      project2 = Project.new(:p2, "")
      project2.deployer = Object.new
      project_repo = ProjectRepo.new(projects: [project2, project1])
      RemoteCleanJob.new(project_repo).run
    end
  end
end

