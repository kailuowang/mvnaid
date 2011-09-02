require File.join File.dirname(__FILE__), %w(.. .. lib vcs_adaptors git_svn_adaptor)
require File.join File.dirname(__FILE__), %w(.. mock_command_runner)

describe GitSvnAdaptor do
  describe "get_local_changes" do
    it "should do git status with ignore_error and display_output" do
      directory = "whatever"
      command_runner = mock("command_runner")
      command_runner.should_receive(:run).with("cd #{directory} && git status",{ignore_error: true, display_output: true})
      adaptor = GitSvnAdaptor.new( command_runner)
      adaptor.get_local_changes(directory)
    end
    it "should return an empty hash if there is no git change" do
      directory = "whatever"
      command_runner = Object.new
      command_runner.stub!(:run).and_return("")
      checker = GitSvnAdaptor.new(command_runner)
      checker.get_local_changes(directory).should == {}
      command_runner.stub!(:run).and_return(nil)
      checker = GitSvnAdaptor.new(command_runner)
      checker.get_local_changes(directory).should == {}
    end
  end

  describe "parse_to_files" do
    it "should parse multiple lines git status with new file message" do
      filename = "dependency-tree.txt"
      filename2 = "lala-tree.txt"
      adaptor = GitSvnAdaptor.new(nil)
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
      adaptor = GitSvnAdaptor.new(nil)
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
      adaptor = GitSvnAdaptor.new(nil)
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
      adaptor = GitSvnAdaptor.new(nil)
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

  describe "parse_last_svn_change" do
    it "should return date when there is hange" do
      svn_info_string = <<-end
Path: .
URL: http://devsvn.tw.net/svn/components/twcomponents-checkout-bridge/trunk
Repository Root: http://devsvn.tw.net/svn/components/twcomponents-checkout-bridge
Repository UUID: 5f0d63c4-0f0f-4af8-9d22-44df65e4ea9f
Revision: 1002
Node Kind: directory
Schedule: normal
Last Changed Author: omalleyj
Last Changed Rev: 1001
Last Changed Date: 2010-04-28 09:00:33 -0400 (Wed, 28 Apr 2010)
      end
       GitSvnAdaptor.new(nil, nil).parse_last_svn_change(svn_info_string).should == Time.parse("2010-04-28 09:00:33 -0400")
    end

    it "should return nil when no change found" do
      GitSvnAdaptor.new(nil, nil).parse_last_svn_change("whatever").should == nil
      GitSvnAdaptor.new(nil, nil).parse_last_svn_change("").should == nil
      GitSvnAdaptor.new(nil, nil).parse_last_svn_change(nil).should == nil
    end
  end

  describe "get_last_svn_change" do
    it "should run git svn info" do
      directory = "testdir"
      msg ="Last Changed Date: 2010-04-28 09:00:33 -0400 (Wed, 28 Apr 2010)"
      command_runner = mock("command_runner")
      command_runner.should_receive(:run).with("cd #{directory} && git svn info",{}).and_return(msg)
      GitSvnAdaptor.new(command_runner).get_last_vcs_change(directory).should == Time.parse("2010-04-28 09:00:33 -0400")
    end
  end

  describe "get_vcs_url" do
    it "should run svn info" do
      directory = "testdir"
      msg =<<end
URL: http://devsvn.tw.net/svn/components/inventory/branches/thoughtdocs_1_2010
Repository Root: http://devsvn.tw.net/svn/components/inventory
"Last Changed Date: 2010-04-28 09:00:33 -0400 (Wed, 28 Apr 2010)"
end
      vcs_adaptor = GitSvnAdaptor.new(nil)
      vcs_adaptor.should_receive(:get_svn_info_message).with(directory).and_return(msg)
      vcs_adaptor.get_vcs_url(directory).should == "http://devsvn.tw.net/svn/components/inventory/branches/thoughtdocs_1_2010"
    end
  end

  describe "update" do
    it "should be able to tell if there is no change updated from the server" do
      command_runner = mock("command_runner")
      command_runner.should_receive(:run).with("cd dir && git svn rebase", {display_output: true}).and_return("is up to date.")
      GitSvnAdaptor.new(command_runner).update("dir").should == false
    end
    it "should be able to tell if there is change updated from the server" do
      command_runner = mock("command_runner")
      command_runner.should_receive(:run).with("cd dir && git svn rebase", {display_output: true}).and_return("rewinding head to replay your work on top of it...")
      GitSvnAdaptor.new(command_runner).update("dir").should == true
    end
  end

  describe "add" do
    it "should run the git add . command" do
      command_runner = mock("command_runner")
      command_runner.should_receive(:run).with("cd dir1 && git add .", {})
      GitSvnAdaptor.new(command_runner).add_all_to_index("dir1")
    end
  end

  describe "checkout" do
    it "should run the git svn clone checkout command and do update immediately for a branch" do
      command_runner = mock("command_runner")
      command_runner.should_receive(:run).once.with("svn log --stop-on-copy http://somesvnurl/branches/branch1 | grep -e '^r[0-9]\\+' -o | tail -n 1").and_return("r5834")
      command_runner.should_receive(:run).ordered.once.with("git svn clone -s http://somesvnurl/ dir1 -r5834")
      command_runner.should_receive(:run).ordered.once.with("cd dir1 && git branch").and_return("")
      command_runner.should_receive(:run).ordered.once.with("cd dir1 && git branch -a | grep -e 'remotes.*branch1'").and_return('remotes/branch1')
      command_runner.should_receive(:run).ordered.once.with("cd dir1 && git checkout remotes/branch1 -b branch1 && git reset --hard")
      adaptor = GitSvnAdaptor.new(command_runner)
      adaptor.should_receive(:update).with("dir1")
      adaptor.checkout("http://somesvnurl/branches/branch1","dir1")
    end
    it "should run the git svn clone checkout command and do update immediately for a tag" do
      command_runner = mock("command_runner")
      command_runner.should_receive(:run).once.with("svn log --stop-on-copy http://somesvnurl/tags/tag1 | grep -e '^r[0-9]\\+' -o | tail -n 1").and_return("r5834")
      command_runner.should_receive(:run).ordered.once.with("git svn clone -s http://somesvnurl/ dir1 -r5834")
      command_runner.should_receive(:run).ordered.once.with("cd dir1 && git branch").and_return("")
      command_runner.should_receive(:run).ordered.once.with("cd dir1 && git branch -a | grep -e 'remotes.*tag1'").and_return('remotes/tags/tag1')
      command_runner.should_receive(:run).ordered.once.with("cd dir1 && git checkout remotes/tags/tag1 -b tag1 && git reset --hard")
      adaptor = GitSvnAdaptor.new(command_runner)
      adaptor.should_receive(:update).with("dir1")
      adaptor.checkout("http://somesvnurl/tags/tag1","dir1")
    end
    it "should run the git svn clone checkout command and do update immediately for trunk" do
      command_runner = mock("command_runner")
      command_runner.should_receive(:run).once.with("svn log --stop-on-copy http://somesvnurl/trunk | grep -e '^r[0-9]\\+' -o | tail -n 1").and_return("r5834")
      command_runner.should_receive(:run).ordered.once.with("git svn clone -s http://somesvnurl/ dir1 -r5834")
      command_runner.should_receive(:run).ordered.once.with("cd dir1 && git branch").and_return("")
      command_runner.should_receive(:run).ordered.once.with("cd dir1 && git branch -a | grep -e 'remotes.*trunk'").and_return('remotes/trunk')
      command_runner.should_receive(:run).ordered.once.with("cd dir1 && git checkout remotes/trunk -b trunk && git reset --hard")
      adaptor = GitSvnAdaptor.new(command_runner)
      adaptor.should_receive(:update).with("dir1")
      adaptor.checkout("http://somesvnurl/trunk","dir1")
    end
    it "should assume trunk if no branch provided" do
      command_runner = mock("command_runner")
      command_runner.should_receive(:run).once.with("svn log --stop-on-copy http://somesvnurl | grep -e '^r[0-9]\\+' -o | tail -n 1").and_return("r5834")
      command_runner.should_receive(:run).ordered.once.with("git svn clone -s http://somesvnurl dir1 -r5834")
      command_runner.should_receive(:run).ordered.once.with("cd dir1 && git branch").and_return("")
      command_runner.should_receive(:run).ordered.once.with("cd dir1 && git branch -a | grep -e 'remotes.*trunk'").and_return('remotes/trunk')
      command_runner.should_receive(:run).ordered.once.with("cd dir1 && git checkout remotes/trunk -b trunk && git reset --hard")
      adaptor = GitSvnAdaptor.new(command_runner)
      adaptor.should_receive(:update).with("dir1")
      adaptor.checkout("http://somesvnurl","dir1")
    end
    it "should not do post checkout if local branch created" do
      command_runner = mock("command_runner")
      command_runner.should_receive(:run).once.with("svn log --stop-on-copy http://somesvnurl | grep -e '^r[0-9]\\+' -o | tail -n 1").and_return("r5834")
      command_runner.should_receive(:run).ordered.once.with("git svn clone -s http://somesvnurl dir1 -r5834")
      command_runner.should_receive(:run).ordered.once.with("cd dir1 && git branch").and_return("master")
      adaptor = GitSvnAdaptor.new(command_runner)
      adaptor.should_receive(:update).with("dir1")
      adaptor.checkout("http://somesvnurl","dir1")
    end
  end

  describe "commit" do
    it "should run the svn commit command" do
      command_runner = MockCommandRunner.new
      GitSvnAdaptor.new(command_runner).commit_current_index("directory", :message)
      command_runner.commands_run.should == [%(cd directory && git commit -m "#{:message}"), %(cd directory && git svn dcommit)]
    end
  end
  describe "commit_with_local_changes" do
    it "should run the add and commit" do

      adaptor = GitSvnAdaptor.new(nil)
      adaptor.should_receive(:add_all_to_index).with(:directory)
      adaptor.should_receive(:commit_current_index).with(:directory, :message)
      adaptor.commit_with_local_changes([], :directory, :message)
    end
  end

end
