require_relative "action"
require File.join File.dirname(__FILE__), %w(.. message_displayer)

class RunJettyJob
  def initialize(project_name, project_repo, command_runner, message_displayer = MessageDisplayer.new)
    @project_repo = project_repo
    @command_runner = command_runner
    @message_displayer = message_displayer
    @project_name = project_name
  end
  def run_jetty_action project
    Action.new(@command_runner, project, "mvn clean jetty:run", {display_output: true})
  end

  def build_projects_job(projects)
    BuildProjectsJob.new(projects, @project_repo, @command_runner, @message_displayer, false)
  end

  def run()
    project = @project_repo.get(@project_name)
    build_projects_job(project.dependencies).run()
    run_jetty_action(project).act()
  end
end