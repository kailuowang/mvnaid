require_relative "build_action"
require_relative "test_action"

class TestProjectsJob
  def initialize(projects, project_repo, command_runner)
    @projects = projects
    @project_repo = project_repo
    @command_runner = command_runner
  end

  def run options = {all_dependents: true}
    to_test = options[:all_dependents] ? projects_to_test : @projects.psort
    to_test.each do |project|
       if(@project_repo.all_projects_dependent_on(project).size > 0)
         build(project)
       else
         test(project)
       end
    end
  end

  def build(project)
     BuildAction.new(@command_runner, project, @project_repo).act
  end

  def test(project)
     TestAction.new(@command_runner, project).act
  end

  def projects_to_test
    projects_to_test = Set.new(@projects)
    @projects.each do |project|
      projects_to_test.merge(@project_repo.all_projects_dependent_on(project))
    end
    projects_to_test.to_a.psort
  end
end