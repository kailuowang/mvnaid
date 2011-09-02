require File.join File.dirname(__FILE__), %w(.. lib project_repo)
require File.join File.dirname(__FILE__), %w(.. lib vcs_adaptors vcs_adaptor_factory)
require "yaml"

def create_yaml_file(file_path, object)
  yaml = object.to_yaml
  yamlFile = File.new(file_path, "w")
  yamlFile.write(yaml)
  yamlFile.close
end

describe ProjectRepo do
  before(:each) do
    @log_file = "test_log.yml"
  end
  
  describe "get" do
    it "should get projects with the correct dependencies and paths" do
      infos = {"testProject" => {local_path: "testDirectory", dependencies: ["testProject2"]},
               "testProject2" => {local_path: "testProject2Directory"}}
      project_repo = ProjectRepo.new(projects_info: infos)
      project1 = project_repo.get("testProject")
      project2 = project_repo.get("testProject2")
      project1.directory.should == "testDirectory"
      project2.directory.should == "testProject2Directory"
      project1.dependencies.size.should == 1
      project1.dependencies.index(project2).should_not == nil
    end

    it "should raise if not found" do
      project_repo = ProjectRepo.new(project_directories: {"testProject" => "testDirectory"})
      lambda { project_repo.get("anotherProjectName") }.should raise_error
    end

    it "should cache found result" do
      project_repo = ProjectRepo.new(project_directories: {"testProject" => "testDirectory"})
      project_repo.get("testProject").should_not == nil
      project_repo.get("testProject").should === project_repo.get("testProject")
    end
  end

  describe "constructor" do
    it "should construct from yaml file" do
      @project_info_file_path = "project_repo_urls.yml"
      vcs_url = "http://svn.dgsp.net/testproject"
      create_yaml_file(@project_info_file_path, {"testProject"=>{vcs_url: vcs_url, vcs_type: :svn, local_path: "testDirectory", dependencies: ["testProject2"]},
                  "testProject2" => { vcs_url: vcs_url, vcs_type: :cvs, local_path: "testDirectory2" },
                  "testProject3" => { vcs_url: vcs_url, vcs_type: :git, local_path: "testDirectory3" }})

      project_repo = ProjectRepo.new( projects_info_file_path: @project_info_file_path );
      project = project_repo.get("testProject")
      project2 = project_repo.get("testProject2")
      project3 = project_repo.get("testProject3")
      project.directory.should == "testDirectory"
      project2.directory.should == "testDirectory2"
      project3.directory.should == "testDirectory3"
      project.dependent_on?(project2).should == true
      project.vcs_url.should == vcs_url
      project.vcs_adaptor.is_a?(SvnAdaptor).should == true

      project2.vcs_adaptor.is_a?(CvsAdaptor).should == true
      project3.vcs_adaptor.is_a?(GitAdaptor).should == true
    end
    
    it "should initialize the modification_status_checker for project" do
      checker = ModificationStatusChecker.new()
      project_repo = ProjectRepo.new(project_directories: {test: ""},modification_status_checker: checker)
      project_repo.get(:test).modification_status_checker.should == checker
    end

    it "should initialize the logger for project" do
      project_repo = ProjectRepo.new(project_directories: {test: ""})
      project_repo.get(:test).instance_variable_get(:@logger).should == project_repo
    end

    it "should set the local correctly for the project" do
      local_project_directory = "a_local_project_dir"
      local_missing_project_directory = "project_not_local_dir"
      file_system = mock("file_system")
      file_system.should_receive(:exists?).with(local_project_directory).and_return true
      file_system.should_receive(:exists?).with(local_missing_project_directory).and_return false
      project_directories = {a_local_project: local_project_directory, a_local_missing_project: local_missing_project_directory}
      project_repo = ProjectRepo.new(project_directories: project_directories, file_system: file_system)
      project_repo.get(:a_local_project).local?.should == true
      project_repo.get(:a_local_missing_project).local?.should == false
    end

    after(:each) do
      File.delete(@project_info_file_path) if @project_info_file_path
    end
  end

  describe "load_project_directories" do
    it "should load from info file" do
      project_repo = ProjectRepo.new()
      project_repo.load_project_directories("p1" => {local_path: "directory1"}).
              should == {"p1" => "directory1"}
    end
  end

  describe "get_log" do
    it "should initialize project log " do
      project_repo = ProjectRepo.new()
      log = project_repo.get_log("p1")
      log.should_not be nil
      project_repo.get_log("p1").should equal log

    end
  end

  describe "load_build_time" do
    it "should load build time" do
      build_time = Time.now
      deploy_time = Time.now - 1000
      project_repo = ProjectRepo.new(project_directories: {"test"=>"dir"}, build_log:{"test" => {build_time: build_time, deploy_time: deploy_time}})
      project = project_repo.get("test")
      project.build_time.should == build_time
      project.deploy_time.should == deploy_time
    end
  end

  describe "persist_build_time" do
    it "should work" do
      build_time = Time.now
      deploy_time = Time.now - 1000
      project_repo = ProjectRepo.new(project_directories: {"test"=>"dir"}, build_log_file_path: @log_file)
      project_repo.get("test").build_time = build_time
      project_repo.get("test").deploy_time = deploy_time
      project_repo.persist_project_logs
      project_repo = ProjectRepo.new(project_directories: {"test"=>"dir"}, build_log_file_path: @log_file)
      project_repo.get("test").build_time.should == build_time
      project_repo.get("test").deploy_time.should == deploy_time
    end
  end

  describe "create_project_log" do
    it "should not ruin existing project log" do
      project = Project.new("test", "")
      build_time = Time.now
      deploy_time = Time.now - 1000
      project.build_time = build_time
      project.deploy_time = deploy_time
      project_repo = ProjectRepo.new(projects: [project])
      project_repo.get_log(project.name)[:local_changed_files_when_last_deploy] = ["plah.jsp"]
      project_repo.update_build_deploy_times_in_project_logs
      project_repo.get_log(project.name).should == {build_time: build_time, deploy_time: deploy_time,  local_changed_files_when_last_deploy: ["plah.jsp"]}
    end
  end

  describe "clean_project_log" do
    it "should remove all project_log and persist" do
      project = Project.new("test", "")
      build_time = Time.now
      project.build_time = build_time
      project_repo = ProjectRepo.new(projects: [project], build_log_file_path: @log_file)
      project_repo.persist_project_logs
      project_repo = ProjectRepo.new(project_directories: {"test"=>""}, build_log_file_path: @log_file)

      project_repo.clean_project_log
      project_repo.get("test").build_time.should == nil
      project_repo = ProjectRepo.new(project_directories: {"test"=>""}, build_log_file_path: @log_file)
      project_repo.get("test").build_time.should == nil
    end
  end

  describe "all_projects" do
    it "should get all projects" do
      project_repo = ProjectRepo.new(project_directories: {"test"=>"","test2"=>""})
      project_repo.all_projects.collect{|p|p.name}.should == ["test","test2"]
    end
  end

  describe "all_projects_dependent_on" do
    it "should return projects in a dependent order" do
      project1 = Project.new(:project1, nil)
      project2 = Project.new(:project2, nil)
      project3 = Project.new(:project3, nil)
      project4 = Project.new(:project4, nil)
      project5 = Project.new(:project5, nil)
      project1.dependencies << project2
      project1.dependencies << project5
      project2.dependencies << project3
      project4.dependencies << project3
      project_repo = ProjectRepo.new(projects:[project1,project2,project3,project4,project5])
      project_repo.all_projects_dependent_on(project3).to_a.should == [project2,project1,project4]
    end
  end

  describe "push_back_build_time" do
    it "should push back and persist" do
     project = Project.new("test", "")
     build_time = Time.now
     project.build_time = build_time
     project_repo = ProjectRepo.new(projects: [project], build_log_file_path: @log_file)
     project_repo.persist_project_logs
     project_repo = ProjectRepo.new(project_directories: {"test"=>""}, build_log_file_path: @log_file)
     project_repo.push_back_build_time 24
     expected_time = build_time - 24*3600
     project_repo.get("test").build_time.should == expected_time
     project_repo = ProjectRepo.new(project_directories: {"test"=>""}, build_log_file_path: @log_file)
     project_repo.get("test").build_time.should == expected_time
    end
  end



  after(:each) do
    File.delete(@log_file) if(File.exist?(@log_file))
  end

end
