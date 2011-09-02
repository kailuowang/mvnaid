require File.join File.dirname(__FILE__), %w(.. lib util)


describe "util" do
  before(:each) do
    klass = Class.new do
      include Util
    end
    @o = klass.new
  end

  describe "load_yaml_hash" do
    it "should return empty hash if file is nil" do
      @o.load_yaml_hash(nil).should == {}
    end
    it "should return empty hash if file doest not exist" do
      @o.load_yaml_hash("a_file_that_does_not_exist.txt").should == {}
    end
  end

  describe "load_properties" do
    it "should raise understandable error if preope" do
      lambda{ Util.load_properties("nonexist_file.txt") }.should raise_error 'Please make sure you have "nonexist_file.txt" with your settings.'
    end
  end

  describe "remote_path" do
    it "should return path with ~ replaced by home/user" do
      Util.remote_path("~/dir", "wangk").should == "home/wangk/dir"
    end

    it "should return path without ~ " do
      Util.remote_path("home/suhdir/dir", "wangk").should == "home/suhdir/dir"
    end
  end
end
