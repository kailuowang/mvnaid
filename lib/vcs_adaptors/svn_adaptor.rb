require File.join File.dirname(__FILE__), %w(.. message_displayer)
require File.join File.dirname(__FILE__), %w(.. jobs action)
require File.join File.dirname(__FILE__), %w(.. command_runner)

class SvnAdaptor
  SVN_STATUS_OPTION = {ignore_error: true, display_output: true}
  attr_reader :command_runner
  def initialize(command_runner, username = nil, message_displayer = MessageDisplayer.new)
    @command_runner = command_runner
    @message_displayer = message_displayer
    @username = username
  end

  def get_local_changes directory
    message = get_svn_status_message(directory)
    return {} if message.nil? || message.length == 0
    parse_to_files(message)
  end

  def get_last_vcs_change directory
    parse_last_svn_change(get_svn_info_message(directory))
  end

  def commit_with_local_changes(local_changes, directory, message)
    local_changes.each do |file, is_new|
      add(directory, file) if is_new
    end
    commit(directory, message)
  end
  
  def update(directory)
    svn_up_message = get_svn_update_message(directory)
    return !svn_up_message.nil? && svn_up_message.include?("Updated to revision ")
  end

  def checkout(url, directory)
    username = "--username #{@username} " if @username and !@username.empty?
    return @command_runner.run("svn #{username}co #{url} #{directory}")
  end

  def add(directory, file_path)
    return Action.new(@command_runner, directory, "svn add '#{file_path}'").act
  end

  def parse_to_files(message)
    changes = {}
    message.scan(/^(.)\s+[\+]?(.+)\s*$/).each do |match|
      changes[match[1].strip] = ( match[0] == "?" )
    end
    changes
  end

  def parse_last_svn_change message
    return nil if message.nil?
    match = message.match(/Last\sChanged\sDate:\s(.+)\s\(/)
    return nil if match.nil?
    Time.parse(match.to_s)
  end

  def status_command
    "svn st"
  end

  def info_command
    "svn info"
  end

   def update_command
    "svn up"
  end

  def get_svn_status_message(directory)
     Action.new(@command_runner, directory, status_command(), SVN_STATUS_OPTION).act
  end

  def get_svn_info_message(directory)
    Action.new(@command_runner, directory, info_command()).act
  end

  def get_svn_update_message(directory)
    Action.new(@command_runner, directory, update_command, {display_output: true}).act
  end

  def get_vcs_url(directory)
    svn_info_message = get_svn_info_message(directory)
    match = svn_info_message.match(/^URL:\s(.+)$/)
    return match[1] unless match.nil?
  end

  def type
    "svn"
  end
  private
  def commit(directory, message)
    return Action.new(@command_runner, directory, %(svn commit -m "#{message}")).act
  end
end