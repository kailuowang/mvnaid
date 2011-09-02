require_relative "build_projects_job"
require_relative "test_projects_job"
require File.join File.dirname(__FILE__), %w(.. message_displayer)
require File.join File.dirname(__FILE__), %w(.. project_repo)
require File.join File.dirname(__FILE__), %w(.. project)
require File.join File.dirname(__FILE__), %w(.. user_interface)
require File.join File.dirname(__FILE__), %w(.. commit_message_builder)

class VcsCommitJob

  def initialize params = {}
    @project_repo = params[:project_repo]
    @command_runner = params[:command_runner]
    @message_displayer = params[:message_displayer] || MessageDisplayer.new
    @user_interface = params[:user_interface]
    @commit_message_builder = params[:commit_message_builder] || CommitMessageBuilder.new(@user_interface)
  end

  def commit(project, message)
    project.vcs_commit(message)
  end

  def get_locally_changed_projects
    @message_displayer.trivial{"getting locally changed projects"}
    @project_repo.all_projects.find_all do |project|
      project.local? && project.get_local_changed_files.size > 0
    end
  end

  def test_all_related_projects(locally_changed_projects)
    @message_displayer.important{"Testing all impacting projects..."}
    TestProjectsJob.new(locally_changed_projects, @project_repo, @command_runner).run
  end

  def run
    commit_message = @commit_message_builder.build
    locally_changed_projects = get_locally_changed_projects()
    return false if !get_permission_to_add_new_files(locally_changed_projects)
    test_all_related_projects(locally_changed_projects)
    locally_changed_projects.each do |project|
      commit(project, commit_message)
    end
    @message_displayer.important{"Commit Successfully Done!"}
  end

  def get_permission_to_add_new_files(changed_projects)
    new_files = get_all_new_files(changed_projects)
    return true if new_files.empty?
    new_files.each do |key,value|
      @message_displayer.important{"New files found in project #{key.name}!"}
      value.each do
        @message_displayer.important{"*   #{value}"}
      end
    end

    @message_displayer.important{"All new files have to be added to proceed with auto commit. Svn ignore files that should be ignored"}
    @user_interface.confirm("Are you sure you want to add these new files?")
  end

  def get_all_new_files(changed_projects)
    all_new_files = {}
    changed_projects.each do |project|
      new_files = project.get_new_files
      all_new_files[project] = new_files if new_files.size > 0
    end
    all_new_files
  end

end