require File.join File.dirname(__FILE__), %w(.. lib file_system)

describe FileSystem do
  describe "mtime" do
    before(:each) do
     @file_path = "testfile.java"
    end

    it "should return nil if file not found" do
      FileSystem.new.mtime("does_not_exist.txt").should == nil
    end

    it "should return mtime if there is file" do
      file = File.new(@file_path, "w")
      file.write("adfasdf")
      file.close
      (FileSystem.new.mtime(file.path) - Time.now).should < 0.1
    end

    after(:each) do
      File.delete(@file_path) if File.exist?(@file_path)
    end
  end

end