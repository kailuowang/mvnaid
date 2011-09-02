require File.join File.dirname(__FILE__), %w(.. project_repo)
require File.join File.dirname(__FILE__), %w(.. message_displayer)
require_relative "test_projects_job"

class VcsUpdateJob
  def initialize project_repo, command_runner, message_displayer = MessageDisplayer.new
    @project_repo = project_repo
    @command_runner = command_runner
    @message_displayer = message_displayer
  end

  def update(project)
    result = project.vcs_update
    if(result && !project.deployer.nil? && project.deployer.respond_to?(:remote_update))
      project.deployer.remote_update
    end
    result
  end

  def build(project)
     TestProjectsJob.new([project], @project_repo,@command_runner).run({all_dependents: false})
  end

  def run
     @project_repo.all_projects.each do |project|
        if project.local? && update(project)
          build(project)
        end
     end
     @message_displayer.important {"All projects vcs updated"}
  end
end