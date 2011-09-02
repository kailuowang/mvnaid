require File.join File.dirname(__FILE__), %w(.. message_displayer)
require File.join File.dirname(__FILE__), %w(.. jobs action)
require File.join File.dirname(__FILE__), %w(.. command_runner)
require_relative "svn_adaptor"
require_relative "git_svn_adaptor"
require 'strscan'
require 'time'

class GitAdaptor < GitSvnAdaptor

  def get_last_vcs_change directory
    fetch_remote_changes(directory)
    parse_last_vcs_change(latest_remote_change(directory))
  end
  
  def parse_last_vcs_change(message)
    return nil if message.nil?
    match = message.match(/Date:\s*(.+)$/)
    return nil if match.nil?
    Time.strptime(match[1].to_s, "%a %b %d %X %Y %Z")
  end
  
  def get_vcs_url(directory)
    remote_message = get_remote_show_message(directory)
    match = remote_message.match(/Fetch URL:\s(.+)$/)
    return match[1] unless match.nil?
  end
  
  def update(directory)
    pull_message = get_pull_message(directory)
    return !pull_message.nil? && pull_message.include?("Updating")
  end

  def checkout(url, directory)
    output = @command_runner.run("git clone #{url} #{directory}")
    "#{output}"
  end
  
  def commit_current_index(directory, message)
    Action.new(@command_runner, directory, %(git commit -m "#{message}")).act
    return Action.new(@command_runner, directory, "git push").act
  end
  
  
  def fetch_remote_changes(directory)
    Action.new(@command_runner, directory, "git fetch").act
  end
  
  def latest_remote_change(directory)
    Action.new(@command_runner, directory, "git log HEAD..origin/master -1").act
  end
  
  def get_remote_show_message(directory)
    Action.new(@command_runner, directory, "git remote show origin").act
  end
  
  def get_pull_message(directory)
    Action.new(@command_runner, directory, "git pull",{display_output: true}).act
  end
  
  def type
    "git"
  end
end
