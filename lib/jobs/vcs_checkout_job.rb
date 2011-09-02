require File.join File.dirname(__FILE__), %w(.. project_repo)
require File.join File.dirname(__FILE__), %w(.. message_displayer)
require File.join File.dirname(__FILE__), %w(.. file_system)

class VcsCheckoutJob
  def initialize project_repo, file_system = FileSystem.new, message_displayer = MessageDisplayer.new
    @project_repo = project_repo
    @file_system = file_system
    @message_displayer = message_displayer
  end

  def run
    @project_repo.all_projects.each do |project|
      exists = @file_system.exists?(project.directory)
      if !exists
        if(project.vcs_url.nil?)
          @message_displayer.important{"#{project.name} does not have vcs url specified"}
        else
          @message_displayer.important{"checking out #{project.name} from #{project.vcs_url}"}
          project.vcs_checkout
        end
      else
        @message_displayer.trivial{"#{project.name} already exists #{project.directory}"}
      end

    end
  end
end