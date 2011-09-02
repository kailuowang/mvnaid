require_relative "file_system"
require File.join File.dirname(__FILE__), "vcs_adaptors", "svn_adaptor"

class ModificationStatusChecker
  
  def initialize(params ={})
    params = {file_system: FileSystem.new,
              message_displayer: MessageDisplayer.new}.merge(params)
    @file_system = params[:file_system]
    @message_displayer = params[:message_displayer]
  end

  def get_last_change project
    last_local_change = get_last_local_modification(project)
    @message_displayer.trivial{"last local change: #{last_local_change || 'no change' }"}
    last_vcs_change = project.get_vcs_change
    @message_displayer.trivial{"last svn change: #{last_vcs_change || 'no change'}"}
    return last_local_change if last_vcs_change.nil?
    return last_vcs_change if last_local_change.nil?
    return [last_vcs_change,last_local_change].max
  end

  def get_last_local_modification project
    latest_time = nil
    project.get_possibly_modified_files.each do |file|
      mtime = @file_system.mtime(File.join(project.directory, file))
      if !mtime.nil? then
        latest_time ||= mtime
        latest_time = mtime if mtime > latest_time
      end
    end
    latest_time
  end
end