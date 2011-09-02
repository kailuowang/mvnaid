require File.join File.dirname(__FILE__), %w(.. message_displayer)
require File.join File.dirname(__FILE__), %w(.. jobs action)
require File.join File.dirname(__FILE__), %w(.. command_runner)
require 'strscan'

class GitSvnAdaptor   < SvnAdaptor
  def update_command
    "git svn rebase"
  end

  def status_command
    "git status"
  end

  def info_command
    "git svn info"
  end
  
  def initialize(command_runner, message_displayer = MessageDisplayer.new)
    super(command_runner, message_displayer)
  end

  def parse_to_files(message)
    changes = {}
    scanner = StringScanner.new message

    if scanner.scan_until /#\s+Changes to be committed:.*?\n#\n/m
      while scanner.scan /#\t(\S.*?):\s+(\S.*?)\n/
        changes[scanner[2]] = false
      end
    end
    
    if scanner.scan_until /#\s+Changed but not updated:.*?\n#\n/m
      while scanner.scan /#\t(\S*):\s+(\S.*?)\n/
        changes[scanner[2]] = false
      end
    end

    if scanner.scan_until /#\s+Untracked files:.*?\n#\n/m
      while scanner.scan /#[ \t]*(\S.*?)\n/
        changes[scanner[1]] = true
      end
    end
    changes
  end

  def update(directory)
    svn_up_message = get_svn_update_message(directory)
    return !svn_up_message.nil? && !svn_up_message.include?("is up to date.")
  end

  def get_branching_revision(url)
    @command_runner.run("svn log --stop-on-copy #{url} | grep -e '^r[0-9]\\+' -o | tail -n 1")
  end

  def post_checkout(url, directory)
    has_local_branch = @command_runner.run("cd #{directory} && git branch")
    if !has_local_branch.empty?
      return
    end
    branch = parse_branch_from_url(url)
    remote_branch = @command_runner.run("cd #{directory} && git branch -a | grep -e 'remotes.*#{branch}'").strip
    @command_runner.run("cd #{directory} && git checkout #{remote_branch} -b #{branch} && git reset --hard")
  end

  def checkout(url, directory)
    repository_url = url[0, url.index("branches") || url.index("tags") || url.index("trunk") || url.length]
    revision = get_branching_revision(url)
    output = @command_runner.run("git svn clone -s #{repository_url} #{directory} -#{revision}")
    post_checkout(url, directory)
    "#{output} #{update(directory)}"
  end

  def parse_branch_from_url(url)
    match = url.match(/.*(?:(?:branches)|(?:tags))\/(.*)/)
    #return match[1] if match
    if (match)
      return match[1]
    end
    return "trunk"
  end

  def commit_with_local_changes(local_changes, directory, message)
    add_all_to_index(directory)
    commit_current_index(directory, message)
  end

  def add_all_to_index(directory)
    return Action.new(@command_runner, directory, "git add .").act
  end

  def commit_current_index(directory, message)
    Action.new(@command_runner, directory, %(git commit -m "#{message}")).act
    return Action.new(@command_runner, directory, %(git svn dcommit)).act
  end

  def type
    "git_svn"
  end
end