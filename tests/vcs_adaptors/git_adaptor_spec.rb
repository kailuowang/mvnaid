require File.join File.dirname(__FILE__), %w(.. .. lib vcs_adaptors git_adaptor)
require File.join File.dirname(__FILE__), %w(.. mock_command_runner)

describe GitAdaptor do
  describe "get_local_changes" do
    it "should do git status with ignore_error and display_output" do
      directory = "whatever"
      command_runner = mock("command_runner")
      command_runner.should_receive(:run).with("cd #{directory} && git status",{ignore_error: true, display_output: true})
      adaptor = GitAdaptor.new( command_runner)
      adaptor.get_local_changes(directory)
    end
    it "should return an empty hash if there is no git change" do
      directory = "whatever"
      command_runner = Object.new
      command_runner.stub!(:run).and_return("")
      checker = GitAdaptor.new(command_runner)
      checker.get_local_changes(directory).should == {}
      command_runner.stub!(:run).and_return(nil)
      checker = GitAdaptor.new(command_runner)
      checker.get_local_changes(directory).should == {}
    end
  end

  describe "parse_to_files" do
    it "should parse multiple lines git status with new file message" do
      filename = "dependency-tree.txt"
      filename2 = "lala-tree.txt"
      adaptor = GitAdaptor.new(nil)
      git_status_string = <<-end
# Untracked files:
#   (use "git add <file>..." to include in what will be committed)
#
#	#{filename}
#   #{filename2}
      end
      adaptor.parse_to_files(git_status_string).should == {filename => true,filename2 => true}
    end
    it "should parse multiple lines git status with new file added message" do
      filename = "dependency-tree.txt"
      adaptor = GitAdaptor.new(nil)
      git_status_string = <<-end
# On branch master
# Changes to be committed:
#   (use "git reset HEAD <file>..." to unstage)
#
#	new file:   #{filename}
      end
      adaptor.parse_to_files(git_status_string).should == {filename => false}
    end

    it "should parse multiple lines git status with modified file message" do
      filename = "INSTALL.txt"
      filename2 = "cruise_config.rb"
      adaptor = GitAdaptor.new(nil)
      git_status_string = <<-end
# Changed but not updated:
#   (use "git add <file>..." to update what will be committed)
#   (use "git checkout -- <file>..." to discard changes in working directory)
#
#	modified:   INSTALL.txt
#	modified:   cruise_config.rb
#
      end
      adaptor.parse_to_files(git_status_string).should == {filename => false,filename2 => false}
    end

    it "should parse muiltiple lines with all types of changes" do
      new_filename = "INSTALL.txt"
      new_added_filename = "laladf.rb"
      modified_filename = "cruise_config.rb"
      modified_filename2 = "cruise_config2.rb"
      adaptor = GitAdaptor.new(nil)
      git_status_string = <<-end
# On branch master
# Changes to be committed:
#   (use "git reset HEAD <file>..." to unstage)
#
#	new file:   #{new_added_filename}
#
# Changed but not updated:
#   (use "git add <file>..." to update what will be committed)
#   (use "git checkout -- <file>..." to discard changes in working directory)
#
#	modified:   #{modified_filename}
#	modified:   #{modified_filename2}
#
# Untracked files:
#   (use "git add <file>..." to include in what will be committed)
#
#	#{new_filename}
      end
      adaptor.parse_to_files(git_status_string).should == {new_added_filename => false, modified_filename => false, modified_filename2 => false, new_filename => true}
    end

# not sure if this is needed in git
#    it "should not include folder with svn properties changed" do
#      filename = "dependency-tree.txt"
#      filename2 = "lala-tree.txt"
#      filename3 = "lalasdfasa-tree.txt"
#      folder = "afolder"
#      adaptor = SvnAdaptor.new(nil)
#      svn_status_string = <<-end
#?       #{filename}
# M       #{folder}
#M       #{filename2}
#A  +    #{filename3}
#      end
#      adaptor.parse_to_files(svn_status_string).keys.should == [filename,filename2,filename3]
#    end

  end

  describe "get_last_vcs_change" do
    before(:each) do
      @command_runner = mock(CommandRunner)
      @adaptor = GitAdaptor.new(@command_runner, nil)
      @command_runner.stub!(:run)
    end

    it "should fetch remote updates" do
      @command_runner.should_receive(:run).with("cd test_directory && git fetch",{})
      
      @adaptor.get_last_vcs_change("test_directory")
    end

    it "should get latest remote change from log" do
      @command_runner.should_receive(:run).with("cd test_directory && git log HEAD..origin/master -1",{})
      
      @adaptor.get_last_vcs_change("test_directory")
    end
    
    it "should return date when there is change" do
      git_log_string = <<-end
commit 98bb354559757e116ca99992661327e22cdc0b51
Author: Some One <someone@somewhere.com>
Date:   Mon Jul 6 23:52:20 2009 -0400

    bumped version
      end
      @command_runner.should_receive(:run).
        with("cd test_directory && git log HEAD..origin/master -1",{}).
        and_return(git_log_string)

       @adaptor.get_last_vcs_change("test_directory").should == Time.parse("2009-07-06 23:52:20 -0400")
    end

    it "should return nil when no change found" do
      @adaptor.parse_last_vcs_change("whatever").should == nil
      @adaptor.parse_last_vcs_change("").should == nil
      @adaptor.parse_last_vcs_change(nil).should == nil
    end
  end

  describe "get_vcs_url" do
    it "should run git remote show origin and parse 'Fetch URL'" do
      directory = "testdir"
      msg =<<end
* remote origin
  Fetch URL: git@tw-6512.twccorp.net:/home/git/repositories/preview.git
  Push  URL: git@tw-6512.twccorp.net:/home/git/repositories/preview.git
  HEAD branch: master
  Remote branch:
    master tracked
  Local branch configured for 'git pull':
    master merges with remote master
  Local ref configured for 'git push':
    master pushes to master (local out of date)
end
      command_runner = mock(CommandRunner)
      command_runner.should_receive(:run).with("cd testdir && git remote show origin", {}).and_return(msg)

      vcs_adaptor = GitAdaptor.new(command_runner, nil)
      vcs_adaptor.get_vcs_url(directory).should == "git@tw-6512.twccorp.net:/home/git/repositories/preview.git"
    end
  end

  describe "update" do
    it "should be able to tell if there is no change updated from the server" do
      command_runner = mock("command_runner")
      command_runner.should_receive(:run).with("cd dir && git pull", {display_output: true}).and_return("Already up-to-date.")
      GitAdaptor.new(command_runner).update("dir").should == false
    end
    
    it "should be able to tell if there is change updated from the server" do
      command_runner = mock("command_runner")
      msg = <<end
remote: Counting objects: 64, done.
remote: Compressing objects: 100% (33/33), done.
remote: Total 38 (delta 18), reused 0 (delta 0)
Unpacking objects: 100% (38/38), done.
From tw-6512.twccorp.net:/home/git/repositories/preview
   6aec6c7..e06c1f1  master     -> origin/master
Updating 6aec6c7..e06c1f1
Fast-forward
 .../applicationContext-catalog-domain.default.xml  |    2 --
 ...applicationContext-promotion-domain.default.xml |    2 --
 ...pplicationContext-promotion-preview.default.xml |   11 +++++++++++
 .../META-INF/applicationContext-preview.web.xml    |   10 ++++++++++
 .../src/main/webapp/WEB-INF/web.xml                |    2 +-
 .../integration/appcontext/CreationTest.java       |    3 +++
 6 files changed, 25 insertions(+), 5 deletions(-)
 create mode 100644 promotion/src/main/resources/applicationContext-promotion-preview.default.xml
 create mode 100644 store-webapp/tw-store-webapp-war/src/main/resources/META-INF/applicationContext-preview.web.xml
end
      command_runner.should_receive(:run).with("cd dir && git pull", {display_output: true}).and_return(msg)
      GitAdaptor.new(command_runner).update("dir").should == true
    end
  end

  describe "add" do
    it "should run the git add . command" do
      command_runner = mock("command_runner")
      command_runner.should_receive(:run).with("cd dir1 && git add .", {})
      GitAdaptor.new(command_runner).add_all_to_index("dir1")
    end
  end

  describe "checkout" do
    it "should run the git clone" do
      command_runner = mock("command_runner")
      command_runner.should_receive(:run).with("git clone url dir1")
      adaptor = GitAdaptor.new(command_runner)
      adaptor.checkout("url","dir1")
    end
  end

  describe "commit" do
    it "should run the git commit command and push the changes to the remote repository" do
      command_runner = mock("command_runner")
      command_runner.should_receive(:run).with("cd dir1 && git commit -m \"message\"", {})
      command_runner.should_receive(:run).with("cd dir1 && git push", {})
      
      GitAdaptor.new(command_runner).commit_current_index("dir1", "message")
    end
  end

  describe "commit_with_local_changes" do
    it "should run the add and commit" do
      adaptor = GitAdaptor.new(nil)
      adaptor.should_receive(:add_all_to_index).with(:directory)
      adaptor.should_receive(:commit_current_index).with(:directory, :message)
      adaptor.commit_with_local_changes([], :directory, :message)
    end
  end

end
