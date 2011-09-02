require File.join File.dirname(__FILE__), %w(.. .. lib vcs_adaptors svn_adaptor)

describe SvnAdaptor do
  describe "get_local_changes" do
    it "should do svn st with ignore_error and display_output and svn info" do
      directory = "whatever"
      command_runner = mock("command_runner")
      command_runner.should_receive(:run).with("cd #{directory} && svn st",{ignore_error: true, display_output: true})
      checker = SvnAdaptor.new( command_runner)
      checker.get_local_changes directory
    end
    it "should return {} if no svn change" do
      directory = "whatever"
      command_runner = Object.new
      command_runner.stub!(:run).and_return("")
      checker = SvnAdaptor.new(command_runner)
      checker.get_local_changes(directory).should == {}
      command_runner.stub!(:run).and_return(nil)
      checker = SvnAdaptor.new(command_runner)
      checker.get_local_changes(directory).should == {}
    end
  end

  describe "parse_to_files" do
    it "should work with one line" do
      filename = "dependency-tree.txt"
      adaptor = SvnAdaptor.new(nil)
      adaptor.parse_to_files("?       #{filename}").keys.should == [filename]
      end
    it "should parse multiple lines svn status message" do
      filename = "dependency-tree.txt"
      filename2 = "lala-tree.txt"
      filename3 = "lalaad tree.txt"
      adaptor = SvnAdaptor.new(nil)
      svn_status_string = <<-end
?       #{filename}
M       #{filename2}
d       #{filename3}
      end
      adaptor.parse_to_files(svn_status_string).keys.should == [filename,filename2,filename3]
    end
    it "should not include folder with svn properties changed" do
      filename = "dependency-tree.txt"
      filename2 = "lala-tree.txt"
      filename3 = "lalasdfasa-tree.txt"
      folder = "afolder"
      adaptor = SvnAdaptor.new(nil)
      svn_status_string = <<-end
?       #{filename}
 M       #{folder}
M       #{filename2}
A  +    #{filename3}
      end
      adaptor.parse_to_files(svn_status_string).keys.should == [filename,filename2,filename3]
    end
    it "should parse if file is new to svn" do
      filename = "dependency-tree.txt"
      filename2 = "lala-tree.txt"
      adaptor = SvnAdaptor.new(nil)
      svn_status_string = <<-end
?       #{filename}
M       #{filename2}
      end
      adaptor.parse_to_files(svn_status_string).should == {filename => true,filename2 => false}
    end
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
       SvnAdaptor.new(nil, nil).parse_last_svn_change(svn_info_string).should == Time.parse("2010-04-28 09:00:33 -0400")
    end

    it "should return nil when no change found" do
      SvnAdaptor.new(nil, nil).parse_last_svn_change("whatever").should == nil
      SvnAdaptor.new(nil, nil).parse_last_svn_change("").should == nil
      SvnAdaptor.new(nil, nil).parse_last_svn_change(nil).should == nil
    end
  end

  describe "get_last_svn_change" do
    it "should run svn info" do
      directory = "testdir"
      msg ="Last Changed Date: 2010-04-28 09:00:33 -0400 (Wed, 28 Apr 2010)"
      command_runner = mock("command_runner")
      command_runner.should_receive(:run).with("cd #{directory} && svn info",{}).and_return(msg)
      SvnAdaptor.new(command_runner).get_last_vcs_change(directory).should == Time.parse("2010-04-28 09:00:33 -0400")
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
      vcs_adaptor = SvnAdaptor.new(nil)
      vcs_adaptor.should_receive(:get_svn_info_message).with(directory).and_return(msg)
      vcs_adaptor.get_vcs_url(directory).should == "http://devsvn.tw.net/svn/components/inventory/branches/thoughtdocs_1_2010"
    end
  end

  describe "update" do
    it "should be able to tell either updated or not" do
      command_runner = mock("command_runner")
      command_runner.should_receive(:run).with("cd dir && svn up", {display_output: true}).and_return("U  #{File.join("dir", "foo.txt")}  \nUpdated to revision 2. ")
      SvnAdaptor.new(command_runner).update("dir").should == true
    end
  end

  describe "add" do
    it "should run the svn add command" do
      command_runner = mock("command_runner")
      command_runner.should_receive(:run).with("cd dir1 && svn add '2.java'", {})
      SvnAdaptor.new(command_runner).add("dir1","2.java")
    end
  end

  describe "checkout" do
    it "should run the svn checkout command" do
      command_runner = mock("command_runner")
      command_runner.should_receive(:run).with("svn co url1 dir1")
      SvnAdaptor.new(command_runner).checkout("url1","dir1")
    end
    it "should run the svn checkout command with username" do
      command_runner = mock("command_runner")
      command_runner.should_receive(:run).with("svn --username user1 co url1 dir1")
      SvnAdaptor.new(command_runner, "user1").checkout("url1","dir1")
    end
  end

  describe "commit" do
    it "should run the svn commit command" do
      command_runner = mock("command_runner")
      command_runner.should_receive(:run).with(%(cd directory && svn commit -m "#{:message}"), {})
      SvnAdaptor.new(command_runner).commit_with_local_changes({}, "directory", :message)
    end
  end

end
