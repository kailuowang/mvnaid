require File.join File.dirname(__FILE__), %w(.. lib option_parser)

describe OptionParser do
  describe "parse" do
    it "should parse -b checkout,shopping" do
       options = OptionParser.parse(["-b", "checkout,shopping"])
       options.build_project_names.should == ["checkout","shopping"] 
    end

    it "should parse --build checkout,shopping" do
       options = OptionParser.parse(["--build", "checkout,shopping"])
       options.build_project_names.should == ["checkout","shopping"]
     end

    it "should parse -r war" do
       options = OptionParser.parse(["-r", "war"])
       options.build_project_names.should == []
       options.jetty_run_project_name.should == "war" 
       end
    it "should parse -runjetty war" do
       options = OptionParser.parse(["--runjetty", "war"])
       options.build_project_names.should == []
       options.jetty_run_project_name.should == "war"
    end

    it "should parse --clean" do
       options = OptionParser.parse(["--clean"])
       options.clean.should == true
    end

    it "should parse --commit" do
       options = OptionParser.parse(["--commit"])
       options.commit.should == true
    end

    it "should parse --update" do
       options = OptionParser.parse(["--update"])
       options.update.should == true
       end

    it "should parse -u" do
       options = OptionParser.parse(["-u"])
       options.update.should == true
    end

    it "should parse -q" do
       options = OptionParser.parse(["-q"])
       options.quiet.should == true
    end

    it "should parse -v" do
       options = OptionParser.parse(["-v"])
       options.verbose.should == true
    end

    it "should parse --pushback 10" do
       options = OptionParser.parse(["--pushback", "10"])
       options.push_back_build_time.should == 10 
    end

    it "should parse --build-all" do
       options = OptionParser.parse(["--build-all"])
       options.build_all.should == true
     end
  end
end
