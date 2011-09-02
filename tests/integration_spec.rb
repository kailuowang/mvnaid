require File.join File.dirname(__FILE__), %w(.. lib jobs_runner)
require File.join File.dirname(__FILE__), %w(.. lib array)
require_relative "mock_command_runner"

def create_yaml_file(file_path, object)
  yaml = object.to_yaml
  yamlFile = File.new(file_path, "w")
  yamlFile.write(yaml)
  yamlFile.close
end

describe "build script" do
  before(:each) do
    @build_log_file_path = "build_log.yml"
    Util.stub!(:load_properties).
                with(anything(), Util::MISSING_BUILD_PROPERTIES).
                and_return({profile: "DOESNT_MATTER"})
  end

  it "should be able to run jetty" do
    info = {  "1"=> {local_path: "dir1", dependencies: ["2"]},
              "2"=> {local_path: "dir2", dependencies: ["3", "4"]},
              "3"=> {local_path: "dir3", dependencies: ["5"]},
              "4"=> {local_path: "dir4", dependencies: ["5","6"]},
              "5"=> {local_path: "dir5" },
              "6"=> {local_path: "dir6"}}
    build_log = {}
    command_runner = MockCommandRunner.new
    file_system = Object.new
    file_system.stub!(:exists?).and_return(true)
    stub_for = proc do |project_name, mtime, build_time, svn_change_time = nil|
      dir = "dir#{project_name}"
      filename = "#{project_name}.java"
      command_runner.stub("cd #{dir} && svn st", "?    #{filename}") unless mtime.nil?
      svn_info_msg = "...Last Changed Date: #{svn_change_time} (w..." unless svn_change_time.nil?
      command_runner.stub("cd #{dir} && svn info", svn_info_msg)
      file_system.stub!(:mtime).with(File.join(dir,filename)).and_return(mtime)
      build_log[project_name] = {build_time: build_time}
    end

    stub_for.call("1", nil, nil)                                #not modified
    stub_for.call("2", Time.now, nil)                           #never build
    stub_for.call("3", nil, nil)                                #not modified
    stub_for.call("4", Time.now-10000, Time.now, Time.now-20000)  #build after last modification
    stub_for.call("5", Time.now, Time.now-10000)                 #modified after last build
    stub_for.call("6", nil, Time.now-10000, Time.now)            #svn updated after last build

    modification_status_checker = ModificationStatusChecker.new(file_system: file_system)

    create_yaml_file(@build_log_file_path, build_log)
    project_repo = ProjectRepo.new({projects_info: info,
                                    modification_status_checker: modification_status_checker,
                                    file_system: file_system,
                                    build_log_file_path: @build_log_file_path,
                                    command_runner: command_runner})


    jobs_runner = JobsRunner.new(["-r", "1", "-q"], project_repo: project_repo, command_runner: command_runner)
    jobs_runner.run()

    command_runner.commands_run.should == ["cd dir5 && svn st",
                                           "cd dir5 && svn info",
                                           "cd dir5 && mvn clean install",
                                           "cd dir3 && svn st",
                                           "cd dir3 && svn info",
                                           "cd dir6 && svn st",
                                           "cd dir6 && svn info",
                                           "cd dir6 && mvn clean install",
                                           "cd dir4 && svn st",
                                           "cd dir4 && svn info",
                                           "cd dir2 && svn st",
                                           "cd dir2 && svn info",
                                           "cd dir2 && mvn clean install",
                                           "cd dir1 && mvn clean jetty:run"]
  end


  it "should be able to clean " do
    info = {  "1"=> {local_path: "dir1"},
              "2"=> {local_path: "dir2"},
              "3"=> {local_path: "dir3"},
              "4"=> {local_path: "dir4"},
              "5"=> {local_path: "dir5"},
              "6"=> {local_path: "dir6"}}
    build_time_proj2 = Time.now - 1000
    build_log = {"1" => {build_time: Time.now}, "2" => {build_time: build_time_proj2}}
    create_yaml_file(@build_log_file_path, build_log)

    project_repo = ProjectRepo.new(projects_info: info, build_log_file_path: @build_log_file_path)
    project_repo.get("2").build_time.should == build_time_proj2 #just to verify

    jobs_runner = JobsRunner.new(["--clean", "-q"], {project_repo: project_repo})
    jobs_runner.run()

    project_repo = ProjectRepo.new(projects_info: info, build_log_file_path: @build_log_file_path)
    project_repo.get("1").build_time.should == nil
    project_repo.get("2").build_time.should == nil
  end

  it "should be able to svn update all project " do
    info = {  "1"=> {local_path: "dir1", dependencies: ["2"]},
              "2"=> {local_path: "dir2", dependencies: ["3"]},
              "3"=> {local_path: "dir3"}}
    file_system = Object.new
    file_system.stub!(:exists?).and_return(true)
    command_runner = MockCommandRunner.new
    command_runner.stub("cd dir2 && svn up","u     file.txt\nUpdated to revision 2")
    project_repo = ProjectRepo.new( projects_info: info,
                                    file_system: file_system,
                                    command_runner: command_runner )
    jobs_runner = JobsRunner.new(["--update", "--quiet"], {project_repo: project_repo, command_runner: command_runner})
    jobs_runner.run()
    command_runner.commands_run.should == ["cd dir3 && svn up",
                                           "cd dir2 && svn up",
                                           "cd dir2 && mvn clean install",
                                           "cd dir1 && svn up"]
  end

  it "should be able to commit projects" do
    command_runner = MockCommandRunner.new
    info = {  "1"=> {local_path: "dir1", dependencies: ["2"]},
              "2"=> {local_path: "dir2", dependencies: ["3"]},
              "3"=> {local_path: "dir3"}}
    file_system = Object.new
    file_system.stub!(:exists?).and_return(true)

    project_repo = ProjectRepo.new( projects_info: info,
                                    file_system: file_system,
                                    command_runner: command_runner )

    user_interface = mock(:user_interface)
    user_interface.should_receive(:prompt).and_return("a_project_name")
    user_interface.should_receive(:prompt).and_return("a_issue_number")
    user_interface.should_receive(:prompt).and_return("a_pair_name")
    user_interface.should_receive(:prompt).and_return("a_dev_name")
    user_interface.should_receive(:prompt).and_return("a_what_is_done_message")
    user_interface.stub!(:confirm).and_return(true)
    expected_commit_message = "a_project_name-a_issue_number [a_pair_name/a_dev_name] a_what_is_done_message"
    svn_st_message = <<end
u       file.txt
?       a_newfile.java
end

    command_runner.stub("cd dir2 && svn st", svn_st_message)
    jobs_runner = JobsRunner.new(["--commit", "--quiet"],
                                  {project_repo: project_repo,
                                   command_runner: command_runner,
                                   user_interface: user_interface,
                                   commit_message_builder: CommitMessageBuilder.new(user_interface)})
    jobs_runner.run()
    command_runner.commands_run.should == ["cd dir3 && svn st",
                                           "cd dir2 && svn st",
                                           "cd dir1 && svn st",
                                           "cd dir2 && mvn clean install",
                                           "cd dir1 && mvn clean test",
                                           "cd dir2 && svn add 'a_newfile.java'", #a third st to get the new files to add
                                           "cd dir2 && svn commit -m \"#{expected_commit_message}\""]
  end

  it "should be able to deploy projects" do
    command_runner = MockCommandRunner.new()
   info = {  "1"=> {local_path: "dir1", dependencies: ["2"]},
              "2"=> {local_path: "dir2", dependencies: ["3"]},
              "3"=> {local_path: "dir3"}}
    project_deploy_specifics = {"1"=>{destination_path: "dest", type: :presentation},
                            "3" => {type: :binary, binary_file_path: "out/3.jar"} }
    project_deploy_info = {general: {restart_script_path: "restart.sh"},
                           project_specifics: project_deploy_specifics}
    file_system = mock(:file_system)
    file_system.stub!(:exists?).and_return(true)
    file_system.stub!(:mtime).with(File.join("dir3","someclass.java")).and_return(Time.now)
    file_system.stub!(:mtime).with(File.join("dir1","product.jsp")).and_return(Time.now)
    project_repo = ProjectRepo.new( projects_info: info,
                                    project_deploy_info: project_deploy_info,
                                    command_runner: command_runner,
                                    file_system: file_system,
                                    build_properties: {username: "user", server: "server1", sandbox_lib_path: "dest/lib"} )

    svn_st_message1 = "
?       product.jsp
"
    svn_st_message3 = "
M       someclass.java
"

    command_runner.stub("cd dir1 && svn st", svn_st_message1)
    command_runner.stub("cd dir3 && svn st", svn_st_message3)


    jobs_runner = JobsRunner.new(["--deploy", "--quiet"],
                                  {project_repo: project_repo,
                                   command_runner: command_runner })
    jobs_runner.run()
    command_runner.commands_run.should == [ "cd dir3 && svn st",
                                            "cd dir3 && svn info",
                                            "cd dir3 && mvn clean install",
                                            "cd out && scp \"3.jar\" \"user@server1:/dest/lib/3.jar\"",
                                            "cd dir1 && svn st",
                                            "cd dir1 && svn info",
                                            "cd dir1 && scp \"product.jsp\" \"user@server1:/dest/product.jsp\"",
                                            "ssh user@server1 \". ./.profile; restart.sh\""]
    end

  describe "sort_by_dependency" do
    before(:each) do
      @projects = []
      (0..11).each do |i|
        p = Project.new("#{i}", "")
        @projects << p
      end
    end

    it "should resolve complex dependencies" do
      @projects[1].dependencies << @projects[0]
      @projects[2].dependencies << @projects[1]
      @projects[3].dependencies << @projects[1]
      @projects[4].dependencies << @projects[5]
      @projects[5].dependencies << @projects[3]
      @projects[6].dependencies << @projects[3]
      @projects[6].dependencies << @projects[2]
      @projects[8].dependencies << @projects[7]
      @projects[8].dependencies << @projects[6]
      @projects[9].dependencies << @projects[7]
      @projects[11].dependencies << @projects[4]
      @projects[11].dependencies << @projects[8]
      @projects[11].dependencies << @projects[9]
      @projects[11].dependencies << @projects[10]

      ProjectRepo.new(projects: @projects).all_projects.collect{|p|Integer(p.name)}.should == [0, 1, 2, 3, 5, 4, 6, 7, 8, 9, 10, 11]
    end
  end

  after(:each) do
     File.delete(@build_log_file_path) if (File.exist?@build_log_file_path)
  end
end
