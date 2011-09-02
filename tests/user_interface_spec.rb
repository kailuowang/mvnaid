require File.join File.dirname(__FILE__), %w(.. lib user_interface)

describe UserInterface do
  describe "yes?" do
    it "should parse yes" do
      UserInterface.new.yes?("yes").should == true
      end
    it "should parse no" do
      UserInterface.new.yes?("no").should == false
    end

    it "should parse y" do
      UserInterface.new.yes?("y").should == true
      end

    it "should parse Y" do
      UserInterface.new.yes?("Y").should == true
    end

    it "should return false for unrecognized command" do
      UserInterface.new.yes?("idontknow").should == false
    end
  end

end
