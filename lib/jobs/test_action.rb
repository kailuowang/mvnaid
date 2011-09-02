class TestAction   < Action

  def initialize command_runner, project
    super command_runner, project, "mvn clean test", {}
    @project = project
  end

  def valid?
    return @project.eligible_for_build?
  end
end