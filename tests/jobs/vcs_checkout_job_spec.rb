require File.join File.dirname(__FILE__), %w(.. .. lib jobs vcs_checkout_job)
require File.join File.dirname(__FILE__), %w(.. mock_command_runner)

describe VcsCheckoutJob do
  describe "run" do
    it "should run svn checkout commands for each non-local project " do
      vcs_adaptor = mock(:vcs_adptor)
      vcs_adaptor.should_not_receive(:checkout).with(:vcs_url1, :dir1)
      vcs_adaptor.should_receive(:checkout).with(:vcs_url2, :dir2)

      project1 = Project.new("1", :dir1, vcs_adaptor: vcs_adaptor)
      project2 = Project.new("2", :dir2, vcs_adaptor: vcs_adaptor)
      project1.vcs_url = :vcs_url1
      project2.vcs_url = :vcs_url2

      file_system = mock(:file_system)
      file_system.should_receive(:exists?).with(:dir1).and_return(true)
      file_system.should_receive(:exists?).with(:dir2).and_return(false)
      project_repo = ProjectRepo.new(projects:[project2, project1])
      VcsCheckoutJob.new(project_repo, file_system).run
    end
  end
end