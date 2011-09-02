require File.join File.dirname(__FILE__), %w(.. project_repo)
require_relative "build_action"
require File.join File.dirname(__FILE__), %w(.. message_displayer)
class BuildProjectsJob
  attr_reader :projects
  attr_reader :must_build_input_projects

  def initialize(projects, project_repo, command_runner, message_displayer = MessageDisplayer.new, must_build_input_projects = true )
    @project_repo = project_repo
    @command_runner = command_runner
    @message_displayer = message_displayer
    @must_build_input_projects = must_build_input_projects
    if projects.nil? || projects.empty?
      @projects = project_repo.all_projects
    elsif projects[0].is_a?(Project)
      @projects = projects
    else
      @projects = projects.collect {|name|@project_repo.get(name)}
    end
  end

  def run()
    build_all_related_projects(@projects, @must_build_input_projects)
    @message_displayer.important {"Build done successfully"}
  end

  def build_all_related_projects(projects, must_build_input_projects)
    get_all_related_projects(projects).each do |project|
      @message_displayer.trivial{"checking project #{project.name}"}
      explicitly_asked = !projects.index(project).nil? && must_build_input_projects
       if (explicitly_asked || project.build_pending?)
         build_action(project).act()
       end
      @message_displayer.trivial{"#{project.name} missing on local"} unless project.local?
    end
  end

  def get_all_related_projects projects
    all_projects = Set.new
    projects.each do |project|
      all_projects << project
      all_projects += get_all_related_projects(project.dependencies)
    end
    all_projects.to_a.psort
  end

  def build_action project
    BuildAction.new(@command_runner, project, @project_repo)
  end

end