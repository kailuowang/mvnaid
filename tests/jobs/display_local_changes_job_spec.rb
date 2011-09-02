require File.join File.dirname(__FILE__), %w(.. .. lib jobs display_local_changes_job)
require File.join File.dirname(__FILE__), %w(.. .. lib message_displayer)

describe DisplayLocalChangesJob do
  describe "run" do
    it "should display local changes from all projects" do
      project1 = Project.new("p1", "")
      project2 = Project.new("p2", "")
      project1.should_receive(:get_local_changes).and_return({"file1" => true })
      project2.should_receive(:get_local_changes).and_return({"file2" => false })
      project_repo = ProjectRepo.new(projects: [project1, project2])
      message_displayer = mock(:message_displayer)
      message_displayer.should_receive(:important).with{"***CHANGES FOUND!!***"}
      message_displayer.should_receive(:important).with{"p1 changes"}
      message_displayer.should_receive(:important).with{"? file1"}
      message_displayer.should_receive(:important).with{"p2 changes"}
      message_displayer.should_receive(:important).with{"m file2"}
      job = DisplayLocalChangesJob.new(project_repo, message_displayer)
      job.run
    end
  end
end