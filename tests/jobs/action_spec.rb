require File.join File.dirname(__FILE__), %w(.. .. lib jobs build_action)
require File.join File.dirname(__FILE__), %w(.. .. lib jobs test_action)
require File.join File.dirname(__FILE__), %w(.. .. lib jobs action)
require File.join File.dirname(__FILE__), %w(.. .. lib remote_command_runner)
require File.join File.dirname(__FILE__), %w(.. .. lib project)
require File.join File.dirname(__FILE__), %w(.. mock_command_runner)

describe Action do
  describe "act" do
    it "should run command with options" do
      project = Project.new("testProject", "dir")
      command_runner = mock("command_runner")
      command = "mvn clean jetty:run"
      options = {display_output: true}
      command_runner.should_receive(:run).with("cd dir && #{command}", options)
      Action.new(command_runner, project, command, options).act()
    end
    it "should use quote to enclose directory with space in it" do
      command_runner = mock("command_runner")
      command_runner.should_receive(:run).with("cd \"dir one\" && ls", {})
      Action.new(command_runner, "dir one", "ls").act()
    end
  end
  describe "initialize" do
    it "should not transform directory if remote command runner" do
      command_runner = RemoteCommandRunner.new nil, nil, nil
      Util.should_not_receive(:path)
      Action.new(command_runner, nil, nil, nil)
    end
  end
end

module Action2
  def self.included(klass)
    klass.extend ClassMethods
  end

  module ClassMethods
    def is_action_with(command_string, options = {}, &initializer)
      define_method :initialize do |command_runner, project|
        @project = project
        @command_runner = command_runner
      end

      define_method :act do
        @command_runner.run("cd #{@project.directory} && #{command_string}", {}) if @project.eligible_for_build?
      end
    end
  end
end

class BuildAction2
  include Action2

  is_action_with('mvn clean install') do
    @project = project
    @command_runner = command_runner
  end
end

class TestAction2
  include Action2

  is_action_with('mvn clean test', :specialization => :test)

  with_post_act do

  end
end


describe BuildAction2 do
  describe "act" do
    it "should build a project" do
      project = Project.new("testProject", "dir")
      project.stub!(:build_pending?).and_return(true)
      project.should_receive(:eligible_for_build?).and_return(true)
      command_runner = mock("command_runner")
      command_runner.should_receive(:run).with("cd dir && mvn clean install", {})
      BuildAction2.new(command_runner, project).act()
    end

#    it "should update project build_time" do
#      project = Project.new("testProject", "dir")
#      project.stub!(:build_pending?).and_return(true)
#      project.should_receive(:eligible_for_build?).and_return(true)
#      command_runner = MockCommandRunner.new
#      BuildAction2.new(command_runner, project).act()
#      (Time.now - project.build_time).should <= 0.001
#    end

    it "should not build projects that are not eligible for build" do
      project = Project.new(:p, "dir1")
      project.should_receive(:eligible_for_build?).and_return(false)
      command_runner = mock(:command_runner)
      command_runner.should_not_receive(:run)
      BuildAction2.new(command_runner, project).act()
    end

  end
end

describe TestAction2 do
  describe "act" do
    it "should test a project" do
      project = Project.new("testProject", "dir")
      project.should_receive(:eligible_for_build?).and_return(true)
      command_runner = mock("command_runner")
      command_runner.should_receive(:run).with("cd dir && mvn clean test", {})
      TestAction2.new(command_runner, project).act()
    end
  end
end



