require File.join File.dirname(__FILE__), %w(.. lib modification_status_checker)

describe ModificationStatusChecker do

  describe "get_last_local_change" do
    it "should return nil if there is svn change but no modification time for the file" do
      directory = "whateverdir"
      command_runner = Object.new
      command_runner.stub!(:run).and_return("d      deletedfile.txt")
      checker = ModificationStatusChecker.new(command_runner: command_runner, file_system: get_mock_file_system)
      checker.get_last_local_modification(Project.new(nil,directory, vcs_adaptor: SvnAdaptor.new(command_runner))).should == nil
    end

    it "should get the last file change time" do
      directory = "whateverdir"
      filename = "dependency-tree.txt"
      filename2 = "timd2.txt"
      filename3 = "tim3.txt"
      command_runner = Object.new
      command_runner.stub!(:run).and_return("?       #{filename}\n?       #{filename2}\n?       #{filename3}")
      file_system = mock("file_system")
      modification_time = Time.now
      file_system.should_receive(:mtime).with(File.join(directory, filename)).and_return(modification_time - 1)
      file_system.should_receive(:mtime).with(File.join(directory, filename2)).and_return(modification_time)
      file_system.should_receive(:mtime).with(File.join(directory, filename3)).and_return(modification_time - 0.3)
      checker = ModificationStatusChecker.new(command_runner: command_runner, file_system: file_system)
      checker.get_last_local_modification(Project.new(nil,directory,vcs_adaptor: SvnAdaptor.new(command_runner))).should == modification_time
    end
  end

  describe "get_last_change" do
    it "should return the last svn change if it's later" do
      last_svn_change = Time.now
      vcs_adaptor = mock("vcs_adaptor")
      vcs_adaptor.should_receive(:get_last_vcs_change).and_return(last_svn_change)
      checker = ModificationStatusChecker.new()
      checker.stub!(:get_last_local_modification).and_return(Time.now-100)
      checker.get_last_change(Project.new("","whateverdir", vcs_adaptor: vcs_adaptor)).should == last_svn_change
    end
    it "should return the last svn change if there is no local change" do
      last_svn_change = Time.now
      vcs_adaptor = mock("vcs_adaptor")
      vcs_adaptor.should_receive(:get_last_vcs_change).and_return(last_svn_change)
      vcs_adaptor.should_receive(:get_local_changes).and_return({})
      checker = ModificationStatusChecker.new()
      checker.get_last_change(Project.new("","whateverdir", vcs_adaptor: vcs_adaptor)).should == last_svn_change
       end
    it "should return the last local change if there is no svn change" do
      last_local_change = Time.now
      vcs_adaptor = mock("vcs_adaptor")
      vcs_adaptor.should_receive(:get_last_vcs_change).and_return(nil)
      checker = ModificationStatusChecker.new()
      checker.stub!(:get_last_local_modification).and_return(last_local_change)
      checker.get_last_change(Project.new("","whateverdir", vcs_adaptor: vcs_adaptor)).should == last_local_change
    end
  end
end

def get_mock_file_system
  file_system = Object.new
  file_system.stub!(:mtime).and_return(nil)
  file_system
end