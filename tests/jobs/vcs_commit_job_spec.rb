require File.join File.dirname(__FILE__), %w(.. .. lib jobs vcs_commit_job)
require File.join File.dirname(__FILE__), %w(.. mock_command_runner)

describe VcsCommitJob do

  describe "run" do
    it "should commit every locally changed project with correct commit message" do
      commit_message_builder = mock(:commit_message_builder)
      commit_message_builder.should_receive(:build).and_return(:a_commit_message)
      vcs_adaptor = mock(:vcs_adaptor)
      vcs_adaptor.stub!(:get_local_changes).and_return({})
      project1,project2,project3 = Project.new(:p1,:d1, vcs_adaptor: vcs_adaptor),Project.new(:p2,:d2,vcs_adaptor: vcs_adaptor),Project.new(:p3,:d3,vcs_adaptor: vcs_adaptor)
      project_repo = ProjectRepo.new(projects: [project1,project2,project3])
      commit_job = VcsCommitJob.new(project_repo: project_repo, commit_message_builder: commit_message_builder)
      commit_job.should_receive(:get_locally_changed_projects).and_return([project1, project2])
      commit_job.should_receive(:get_permission_to_add_new_files).and_return(true)
      commit_job.stub!(:test_all_related_projects)
      commit_job.should_receive(:commit).with(project1,:a_commit_message)
      commit_job.should_receive(:commit).with(project2,:a_commit_message)
      commit_job.run
      end
    it "should exit if no permission to add new files" do
      user_interface = mock(:user_interface)
      user_interface.stub!(:prompt).and_return("a_commit_message")
      project1 = Project.new(:p1,:d1)
      project_repo = ProjectRepo.new(projects:[project1])
      commit_job = VcsCommitJob.new(project_repo: project_repo, user_interface: user_interface)
      commit_job.should_receive(:get_locally_changed_projects).and_return([project1])
      commit_job.should_receive(:get_permission_to_add_new_files).and_return(false)
      commit_job.should_not_receive(:test_all_related_projects)
      commit_job.should_not_receive(:commit)
      commit_job.run.should == false
    end
  end
  
  describe "commit" do
    it "should add all new files first" do
       vcs_adaptor = SvnAdaptor.new(MockCommandRunner.new)
       vcs_adaptor.should_receive(:get_local_changes).with("a_directory").and_return({a_new_file: true, an_exisiting_modified_file: false})
       vcs_adaptor.should_receive(:add).with("a_directory", :a_new_file)
       vcs_adaptor.should_not_receive(:add).with("a_directory", :an_exisiting_modified_file)
       project = Project.new(:whatever,"a_directory", vcs_adaptor: vcs_adaptor)
       VcsCommitJob.new.commit(project, nil)
    end

    it "should use vcs_adaptor to commit" do
      vcs_adaptor = mock("vcs_adaptor")
      local_changes ={an_exisiting_modified_file: false}
      vcs_adaptor.stub!(:get_local_changes).and_return(local_changes)
      vcs_adaptor.should_receive(:commit_with_local_changes).with(local_changes, :a_directory, :a_commit_message)
      project = Project.new(:whatever, :a_directory, vcs_adaptor: vcs_adaptor)
      VcsCommitJob.new.commit(project, :a_commit_message)
      end

    it "should not try to commit if there is no local change" do
      vcs_adaptor = mock("vcs_adaptor")
      vcs_adaptor.stub!(:get_local_changes).and_return({})
      vcs_adaptor.should_not_receive(:commit)
      project = Project.new(:whatever, :a_directory, vcs_adaptor: vcs_adaptor)
      VcsCommitJob.new.commit(project, :a_commit_message)
    end
  end

  describe "get_locally_changed_projects" do
    it "should work" do
      vcs_adaptor = mock(vcs_adaptor)
      vcs_adaptor.should_receive(:get_local_changes).with(:changed_directory).and_return({an_exisiting_modified_file: false})
      vcs_adaptor.should_receive(:get_local_changes).with(:not_changed_directory).and_return({})
      changed_project = Project.new(:changed_project, :changed_directory, vcs_adaptor: vcs_adaptor)
      not_changed_project = Project.new(:not_changed_project, :not_changed_directory, vcs_adaptor: vcs_adaptor)
      project_repo = ProjectRepo.new(projects:[changed_project, not_changed_project])
      VcsCommitJob.new(project_repo: project_repo).get_locally_changed_projects.should == [changed_project]
    end

    it "should not try to check non-local-project" do
      vcs_adaptor = mock(vcs_adaptor)
      vcs_adaptor.should_receive(:get_local_changes).with(:a_directory).and_return({})
      vcs_adaptor.should_not_receive(:get_local_changes).with(:missing_directory)
      local_project = Project.new(:local_project, :a_directory, vcs_adaptor: vcs_adaptor)
      none_local_project = Project.new(:none_project, :missing_directory, local: false, vcs_adaptor: vcs_adaptor)
      project_repo = ProjectRepo.new(projects:[local_project, none_local_project])
      VcsCommitJob.new(project_repo: project_repo).get_locally_changed_projects
    end
  end

  describe "get_all_new_files" do
    it "should work" do
      vcs_adaptor = mock(:vcs_adaptor)
      vcs_adaptor.should_receive(:get_local_changes).with(:directory1).and_return({:file1a => true, :file1b => false})
      vcs_adaptor.should_receive(:get_local_changes).with(:directory2).and_return({:file2a => false, :file2b => true})
      vcs_adaptor.should_receive(:get_local_changes).with(:directory3).and_return({})
      project1, project2, project3 = Project.new(:project1,:directory1, vcs_adaptor: vcs_adaptor),
                                     Project.new(:project2, :directory2, vcs_adaptor: vcs_adaptor),
                                     Project.new(:project3, :directory3, vcs_adaptor: vcs_adaptor)
      VcsCommitJob.new().get_all_new_files([project1, project2, project3]).should =={project1 =>[:file1a],project2 => [:file2b]}
    end
  end

  describe "get_permission_to_add_new_files" do
    it "should call ui to ask for permission and return response" do
      vcs_adaptor = mock(:vcs_adaptor)
      vcs_adaptor.stub!(:get_local_changes).and_return({f1: true, f2: false})
      [true, false].each do |response|
        user_interface = mock(:user_interface)
        user_interface.should_receive(:confirm).with("Are you sure you want to add these new files?").and_return(response)
        project = [Project.new(:test_project, nil, vcs_adaptor: vcs_adaptor)]
        VcsCommitJob.new(user_interface: user_interface).get_permission_to_add_new_files(project).should == response
      end
    end

    it "should not call ui and return true if there is no new files" do
      vcs_adaptor = mock(:vcs_adaptor)
      vcs_adaptor.stub!(:get_local_changes).and_return({f1: false})
      user_interface = mock(:user_interface)
      user_interface.should_not_receive(:confirm)
      projects = [Project.new(:test_project, nil, vcs_adaptor: vcs_adaptor)]
      VcsCommitJob.new(user_interface: user_interface).
              get_permission_to_add_new_files(projects).should == true
    end
  end
end


