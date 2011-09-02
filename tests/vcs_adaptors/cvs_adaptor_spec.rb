require File.join File.dirname(__FILE__), %w(.. .. lib vcs_adaptors cvs_adaptor)

describe CvsAdaptor do
  describe "checkout" do
    it "should call cvs co" do
      command_runner = mock("command_runner")
      command_runner.should_receive(:run).with("cvs co -d dir -r url", {ignore_error: true})
      CvsAdaptor.new(command_runner).checkout("url","dir")
    end
  end

  describe "update" do
    it "should call cvs update" do
      command_runner = mock("command_runner")
      command_runner.should_receive(:run).with("cd dir && cvs update -d", {ignore_error: true}).and_return("some_message")
      CvsAdaptor.new(command_runner).update("dir")
    end

    it "should check for conflict" do
      command_runner = mock("command_runner")
      command_runner.stub!(:run).and_return("some message")
      cvs_adaptor = CvsAdaptor.new(command_runner)
      cvs_adaptor.should_receive(:parse_to_files).with("some message")
      cvs_adaptor.update("dir")
    end
  end

  describe "parse_to_files" do
    it "should parse M files" do
      filename1 = "mvc/orderItemAvailability.jspf"
      cvs_message = <<end
M #{filename1}
cvs update: Updating mvc/account
cvs update: Updating mvc/cart
end
      CvsAdaptor.new(nil).parse_to_files(cvs_message).should == {filename1 => false}
    end

    it "should display error if there is conflict" do
       filename2 = "mvc/cart/shoppingcart.jsp"
      cvs_message = <<end
C #{filename2}
end
      message_displayer = mock(:message_displayer)
      message_displayer.should_receive(:important).with{"!! THERE ARE CVS CONFLICT ON #{filename2}"}
      CvsAdaptor.new(nil, message_displayer).parse_to_files(cvs_message) 
    end

    it "should parse new files" do
      filename1 = "mvc/orderItemAvailability.jspf"
      cvs_message = <<end
? #{filename1}
end
      CvsAdaptor.new(nil).parse_to_files(cvs_message).should == {filename1 => true}
    end

    it "should parse new files added" do
      filename1 = "mvc/orderItemAvailability.jspf"
      cvs_message = <<end
A #{filename1}
end
      CvsAdaptor.new(nil).parse_to_files(cvs_message).should == {filename1 => false}
    end
  end



  describe "add" do
    it "should use cvs add" do
      command_runner = mock("command_runner")
      command_runner.should_receive(:run).with("cd dir && cvs add file1.jsp", {})
      CvsAdaptor.new(command_runner).add("dir", "file1.jsp")
    end
  end

  describe "commit_with_local_changes" do
# ignoring the commit because the hook prevent commit automation    
#    it "should do simple cvs commit if no local changes" do
#      command_runner = mock("command_runner")
#      command_runner.should_receive(:run).with("cd dir && cvs commit -m \"some message\"", {})
#      CvsAdaptor.new(command_runner).commit_with_local_changes({}, "dir", "some message")
#    end

    it "should do add if there is new file in local changes" do
      command_runner = mock("command_runner")
      command_runner.stub!(:run)
      cvs_adaptor = CvsAdaptor.new(command_runner)
      cvs_adaptor.should_receive(:add).with("dir", "file1.jsp")
      cvs_adaptor.should_not_receive(:add).with("dir", "file2.jsp")
      cvs_adaptor.commit_with_local_changes({"file2.jsp" => false, "file1.jsp" => true}, "dir", "whatever")
    end
  end

  describe "get_local_changes" do
    it "should run cvs -n update" do
      directory = "whatever"
      command_runner = mock("command_runner")
      command_runner.should_receive(:run).with("cd #{directory} && cvs -n update",CvsAdaptor::CVS_COMMAND_OPTION)
      cvs_adaptor = CvsAdaptor.new( command_runner)
      expected_changes = {filename1: true}
      cvs_adaptor.should_receive(:parse_to_files).and_return(expected_changes)
      cvs_adaptor.get_local_changes(directory).should == expected_changes
    end
  end

end