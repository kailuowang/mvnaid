require_relative "action"

class BuildAction < Action

  def initialize command_runner, project, build_time_historian = nil
    super command_runner, project, "mvn clean install", {}
    @project = project
    @build_time_historian = build_time_historian
  end

  def valid?
    return @project.eligible_for_build?
  end

  def post_act
    @project.build_time = Time.now
    @build_time_historian.persist_project_logs unless @build_time_historian.nil?
  end
end