require File.join File.dirname(__FILE__),"..", "lib", "deployers", "deployer_factory"

describe DeployerFactory do
  describe "create_deployer" do
    it "should create binary deployer if type is binary" do
      project = Project.new(:p1, nil)
      project_repo = mock(:repo)
      deploy_factory = DeployerFactory.new(general: {}, project_specifics: {p1: {type: :binary}}, project_repo: project_repo)
      deployer = deploy_factory.create_deployer(project)
      deployer.is_a?(BinaryDeployer).should == true
      deployer.project_repo.should == project_repo
      deployer.project.should == project
    end

    it "should create presentation deployer with destination, username and remote_post_update_command" do
      project = Project.new(:p1, nil)
      project1_deploy_info = {destination_path: "dest", type: :presentation, remote_post_update_command: "remotescript.sh"}
      build_properties = { username: "user1", server: "server1"}
      project_specifics = {p1: project1_deploy_info}
      deploy_factory = DeployerFactory.new(project_specifics: project_specifics, build_properties: build_properties)
      PresentationDeployer.should_receive(:new).with({ project: project,
                                                       destination_path: "dest",
                                                       server: "server1",
                                                       command_runner: nil,
                                                       destination_username: "user1",
                                                       remote_post_update_command: "remotescript.sh"})
      deploy_factory.create_deployer(project)
    end

    it "should create presentation deployer with filtered destination path" do
      project = Project.new(:p1, nil)
      project1_deploy_info = {destination_path: "dest", type: :presentation}
      build_properties = { server: "server1"}
      project_specifics = {p1: project1_deploy_info}
      deploy_factory = DeployerFactory.new(project_specifics: project_specifics, build_properties: build_properties)
      deploy_factory.should_receive(:filter_path).with("dest")
      deploy_factory.create_deployer(project)
    end

    it "should not create presentation deployer when server is not set" do
      project = Project.new(:p1, nil)
      project1_deploy_info = {target: "whatever.jar", type: :presentation}
      build_properties = {username: "user", sandbox_lib_path: "dest/lib"}
      params = { general: {},
                project_specifics: {p1: project1_deploy_info},
                build_properties: build_properties }

      deployer_factory = DeployerFactory.new(params)
      deployer_factory.create_deployer(project).should be_nil
    end

    it "should create deployers with default destination_path and type" do
      project = Project.new(:p1, nil)
      project1_deploy_info = {target: "whatever.jar"}
      default = { type: :binary }
      build_properties = {username: "user", server: "server1", sandbox_lib_path: "dest/lib"}
      params = { general: default,
                              project_specifics: {p1: project1_deploy_info},
                              build_properties: build_properties }

      deployer_factory = DeployerFactory.new(params)
      deployer = deployer_factory.create_deployer(project)
      deployer.is_a?(BinaryDeployer).should == true
      deployer.instance_variable_get(:@destination_path).should == "dest/lib"
      deployer.instance_variable_get(:@server).should == "server1"
      deployer.instance_variable_get(:@destination_username).should == "user"
    end

    it "should be able to create remote deployer when type is remote" do
      project = Project.new(:p1, nil)
      project1_deploy_info = {remote_location: "remote_dir", type: :remote}
      build_properties = { username: "user1", server: "server1"}
      params = { general: {},
                  project_specifics: {p1: project1_deploy_info},
                  build_properties: build_properties }

      deployer_factory = DeployerFactory.new(params)
      deployer = deployer_factory.create_deployer(project)
      deployer.is_a?(RemoteDeployer).should == true
      deployer.instance_variable_get(:@remote_command_runner).user.should == "user1"
      deployer.instance_variable_get(:@remote_location).should == "remote_dir"
      deployer.instance_variable_get(:@remote_command_runner).server.should == "server1"
    end

    it "should be not create remote deployer when there is no server set" do
      project = Project.new(:p1, nil)
      project1_deploy_info = {remote_location: "remote_dir", type: :remote}
      build_properties = { username: "user1"}
      params = { general: {},
                project_specifics: {p1: project1_deploy_info},
                build_properties: build_properties }

      deployer_factory = DeployerFactory.new(params)
      deployer_factory.create_deployer(project).should be_nil
    end

    it "should create deployers" do
      project_directories = {"project1" => "dir1", "project2" => "dir2"}
      project_repo = ProjectRepo.new(project_directories: project_directories)
      deployer = Object.new
      project_repo.should_receive(:create_deployer).and_return(deployer)
      project_repo.get("project1").deployer = deployer
    end
  end

  describe "get_binary_path" do
    it "should generate from project specifics and m2 repository path specified in the build properties" do
      project1_specific = {binary_file_path: '${m2_repository}/project1/project1.jar'}
      build_properties = { m2_repository: "~/m2/repository"}
      params = {build_properties: build_properties }
      deployer_factory = DeployerFactory.new(params)
      deployer_factory.get_binary_path(project1_specific).should == "~/m2/repository/project1/project1.jar"
    end
    it "should generate from project specifics and m2 repository path specified in the build properties for multiple jars" do
      project1_specific = {binary_file_path: ['${m2_repository}/project1/project1.jar','${m2_repository}/project1/project2.jar']}
      build_properties = { m2_repository: "~/m2/repository"}
      params = {build_properties: build_properties }
      deployer_factory = DeployerFactory.new(params)
      deployer_factory.get_binary_path(project1_specific).should == ["~/m2/repository/project1/project1.jar", "~/m2/repository/project1/project2.jar"]
    end
  end

  describe "filter_path" do
    it "should replace variables with values defined in build_properties" do
      build_properties = {some_variable: "some_value"}
      deployer_factory = DeployerFactory.new(build_properties: build_properties)
      raw_path = "${some_variable}/bin"
      deployer_factory.should_receive(:find_variables).twice.with(raw_path).and_return([:some_variable])
      deployer_factory.filter_path(raw_path).should == "some_value/bin"
      build_properties[:some_variable] = "other_value"
      deployer_factory.filter_path(raw_path).should == "other_value/bin"
    end

    it "should return nil if raw is nil" do
      DeployerFactory.new.filter_path(nil).should be_nil
    end

    it "should raise meaningful error if variable not defined in the build properties" do
      lambda { DeployerFactory.new(build_properties: {}).filter_path("${some_variable}/dir") }.should raise_error "some_variable is not defined in the build.properties file"
    end
  end

  describe "find_variables" do
    it "should find 1 variable with token format ${XXX}" do
      DeployerFactory.new.find_variables("${home}/bin").should == [:home]      
    end
    it "should find 2 variables with token format ${XXX}" do
      DeployerFactory.new.find_variables("${home}/bin/${project}").should == [:home, :project]      
    end

  end
end