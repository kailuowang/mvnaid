require File.join File.dirname(__FILE__), "..","project"
require File.join File.dirname(__FILE__), "..","message_displayer"
class VcsAdaptorFactory

  def initialize(command_runner, default_vcs_type = nil, default_username = nil, message_displayer = MessageDisplayer.new)
    @message_displayer = message_displayer
    @default_vcs_type = default_vcs_type  || :svn
    @default_username = default_username
    @command_runner = command_runner
  end

  def set_vcs_adaptor(project, project_info)
     project.vcs_adaptor = create_vcs_adaptor(project_info)
    if project_info
      project.vcs_url = project_info[:vcs_url]
    else
      @message_displayer.trivial{"vcs info missing for project #{project.name}"}
    end
  end

  def create_vcs_adaptor(vcs_info)
    vcs_type = vcs_info[:vcs_type] if vcs_info
    vcs_type ||= @default_vcs_type
    case vcs_type.to_sym
      when :cvs
        CvsAdaptor.new(@command_runner, @message_displayer)
      when :svn
        SvnAdaptor.new(@command_runner, @default_username, @message_displayer)
      when :git_svn
        GitSvnAdaptor.new(@command_runner, @message_displayer)
      when :git
        GitAdaptor.new(@command_runner, @message_displayer)
      else
        raise "unrecognized type #{vcs_type}"
    end
  end
end