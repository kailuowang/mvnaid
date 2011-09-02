require File.join File.dirname(__FILE__), %w(.. lib project)

describe Project do

  describe "get_local_changes" do
    it "should cache result" do
      project = Project.new(:p1, nil)
      project.vcs_adaptor = mock(:vcs_adpator)
      changes = {p: true}
      project.vcs_adaptor.should_receive(:get_local_changes).and_return(changes)
      project.get_local_changes.should eql changes;
      project.get_local_changes.should eql changes;

    end
  end

  describe "dependent_on?" do
    it "should return true if directly dependent on" do
      project = Project.new(nil, nil)
      project_b = Project.new(nil, nil)
      project.dependencies << project_b
      project.dependent_on?(project_b).should == true
    end
    it "should return false if not dependent on" do
      project = Project.new(nil, nil)
      project_b = Project.new(nil, nil)
      project.dependent_on?(project_b).should == false
    end
    it "should return true if indirectly dependent on" do
      project1 = Project.new(nil, nil)
      project2 = Project.new(nil, nil)
      project3 = Project.new(nil, nil)
      project1.dependencies << project2
      project2.dependencies << project3
      project1.dependent_on?(project3).should == true
    end
  end

  describe "eligible_for_build?" do
    it "should return false if no pom file" do
      file_system = mock(:filesystem)
      file_system.should_receive(:exists?).with(File.join("dir1","pom.xml")).and_return(false)
      project = Project.new(:p1, "dir1", file_system: file_system)
      project.eligible_for_build?.should == false
    end
  end

  describe "modification_time" do
    it "should return nil if there is no modification_status_checker" do
      project = Project.new(nil, nil)
      project.modification_time.should == nil
    end

    it "should cache result" do
      modification_status_checker = mock(modification_status_checker)
      modification_status_checker.should_receive(:get_last_change).exactly(1).and_return(Time.now - 1)
      project = Project.new(nil, nil, modification_status_checker: modification_status_checker)
      project.modification_time.should == project.modification_time
    end
  end

  describe "deploy" do
    it "should set deploy time" do
      project = Project.new(:p1,nil)
      deployer = mock(:deployer)
      deployer.should_receive(:deploy)
      project.deployer = deployer
      project.deploy
      (Time.now - project.deploy_time).should <= 0.1
    end

    it "should return deployer's deploy method return value" do
      project = Project.new(:p1,nil)
      deployer = mock(:deployer)
      deploy_result = Object.new
      deployer.should_receive(:deploy).and_return(deploy_result)
      project.deployer = deployer
      project.deploy.should == deploy_result
    end
  end

  describe "deploy_pending?" do
    it "should return false if there is no deployer" do
      project = Project.new(nil, nil)
      project.deployer = nil
      project.deploy_time = Time.now - 100
      project.stub!(:modification_time).and_return(Time.now)
      project.deploy_pending?.should == false      
    end

    it "should return true if last modification time is after last deploy time" do
      project = Project.new(nil, nil)
      project.deployer = Object.new
      project.deploy_time = Time.now - 100
      project.stub!(:modification_time).and_return(Time.now)
      project.deploy_pending?.should == true
    end 

    it "should return false if last modification time is before last deploy time" do
      project = Project.new(nil, nil)
      project.deploy_time = Time.now
      project.deployer = Object.new
      project.stub!(:modification_time).and_return(Time.now - 100)
      project.deploy_pending?.should == false
    end

    it "should return false if last modification time is nil" do
      project = Project.new(nil, nil)
      project.deployer = Object.new
      project.deploy_time = Time.now
      project.stub!(:modification_time).and_return(nil)
      project.deploy_pending?.should == false
    end

    it "should return true if last deploy time is nil" do
      project = Project.new(nil, nil)
      project.deployer = Object.new
      project.deploy_time = nil
      project.stub!(:modification_time).and_return(Time.now)
      project.deploy_pending?.should == true
    end
  end


  describe "build_pending?" do
    it "should return true if modified time is larger than last build time" do
      modification_status_checker = Object.new
      modification_status_checker.stub!(:get_last_change).and_return(Time.now)
      project = Project.new(nil, nil, modification_status_checker: modification_status_checker)
      project.build_time = Time.now - 1
      project.stub!(:eligible_for_build?).and_return(true)
      project.build_pending?.should == true
    end

    it "should return false if modified time is smaller than last build time" do
      modification_status_checker = Object.new
      modification_status_checker.stub!(:get_last_change).and_return(Time.now - 1)
      project = Project.new(nil, nil, modification_status_checker: modification_status_checker)
      project.build_time = Time.now
      project.stub!(:eligible_for_build?).and_return(true)
      project.build_pending?.should == false
    end

    it "should return false if modified time is nil" do
      modification_status_checker = Object.new
      modification_status_checker.stub!(:get_last_change).and_return(nil)
      project = Project.new(nil, nil,modification_status_checker: modification_status_checker)
      project.stub!(:eligible_for_build?).and_return(true)

      project.build_pending?.should == false
      project.build_time = Time.now

      project.build_pending?.should == false
    end

    it "should return true if build_time is nil and modified time is not nil" do
      modification_status_checker = Object.new
      modification_status_checker.stub!(:get_last_change).and_return(Time.now)
      project = Project.new(nil, nil, modification_status_checker: modification_status_checker)
      project.stub!(:eligible_for_build?).and_return(true)
      project.build_pending?.should == true
    end

    it "should return false if not local" do
      project = Project.new(nil, nil, local: false)
      project.stub!(:eligible_for_build?).and_return(true)
      project.build_pending?.should == false
    end

    it "should return false if not eligible_for_build" do
      modification_status_checker = Object.new
      modification_status_checker.stub!(:get_last_change).and_return(Time.now)
      project = Project.new(nil, nil, modification_status_checker: modification_status_checker)
      project.should_receive(:eligible_for_build?).and_return(false)
      project.build_pending?.should == false
    end
  end

  describe "get_possibly_modified_files" do
    it "should return both previous local changes and current local changes" do
      file_system = mock(:file_system)
      file_system.stub!(:exists?).and_return true
      project = Project.new(nil, nil, file_system: file_system )
      project.should_receive(:get_local_changed_files).and_return(["file1.jsp", "file2.jsp"])
      project.should_receive(:get_local_changed_files_when_last_deploy).and_return(["file2.jsp", "file3.jsp"])
      project.get_possibly_modified_files.should ==  ["file1.jsp", "file2.jsp", "file3.jsp"]
    end
    it "should return current local changes if previous is empty" do
      project = Project.new(nil, nil)
      project.should_receive(:get_local_changed_files).and_return(["file1.jsp", "file2.jsp"])
      project.should_receive(:get_local_changed_files_when_last_deploy).and_return([])
      project.get_possibly_modified_files.should ==  ["file1.jsp", "file2.jsp"]
    end

     it "should check if file exists" do
       file_system = mock(:file_system)
       project = Project.new(nil, nil, file_system: file_system)
       project.should_receive(:get_local_changed_files).and_return(["file1.jsp"])
       project.should_receive(:get_local_changed_files_when_last_deploy).and_return(["file2.jsp", "file3.jsp"])
       file_system.should_receive(:exists?).with("file2.jsp").and_return(true)
       file_system.should_receive(:exists?).with("file3.jsp").and_return(false) 
       project.get_possibly_modified_files.should ==  ["file1.jsp", "file2.jsp"]
    end
  end

  describe "get_previous_local_changed_files" do
    it "should remember the last local changes" do
      logger = mock(:logger)
      project_log = {}
      logger.stub!(:get_log).with("p1").and_return(project_log)
      vcs_adaptor = mock(:vcs_adaptor)
      deployer = mock(:deployer)
      deployer.stub!(:deploy)
      project = Project.new("p1", nil, vcs_adaptor: vcs_adaptor, logger: logger, deployer: deployer)
      changes_happened_earlier = {"file1.jsp" => false, "file2.jsp" => false}
      vcs_adaptor.should_receive(:get_local_changes).and_return(changes_happened_earlier)
      project.get_local_changes
      project.deploy
      changes_happened_later = {"file3.jsp" => false}
      vcs_adaptor.should_receive(:get_local_changes).and_return(changes_happened_later)
      project_recreated = Project.new("p1", nil, vcs_adaptor: vcs_adaptor, logger: logger)
      project_recreated.get_local_changes
      project_recreated.get_local_changed_files_when_last_deploy.should == ["file1.jsp", "file2.jsp"]
    end

    it "should return empty if no log" do
      Project.new("p1", nil).get_local_changed_files_when_last_deploy.should == []
    end


  end

end