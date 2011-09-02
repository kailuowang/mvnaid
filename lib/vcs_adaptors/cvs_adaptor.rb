class CvsAdaptor
  CVS_COMMAND_OPTION = {ignore_error: true}

  def initialize(command_runner, message_displayer = MessageDisplayer.new)
    @command_runner = command_runner
    @message_displayer = message_displayer
  end

  def checkout(url, dir)
    @command_runner.run("cvs co -d #{dir} -r #{url}", CVS_COMMAND_OPTION)
  end
  
  def get_local_changes directory, command_runner = @command_runner
    message = Action.new(command_runner, directory, "cvs -n update", CVS_COMMAND_OPTION).act
    parse_to_files message
  end

  def update_command
    "cvs update -d"
  end

  def update(directory)
    message = Action.new(@command_runner, directory, update_command, CVS_COMMAND_OPTION).act
    parse_to_files(message)
    @message_displayer.important {"CVS UPDATED CALLED BUT NOT NECCESSARILY RETURN ACTUAL UPDATE STATUS!"}
    true
  end

  def add(directory, file_path)
    Action.new(@command_runner, directory, "cvs add #{file_path}").act
  end

  def commit_with_local_changes(local_changes, directory, message)
    local_changes.each do |file, is_new|
      add(directory, file) if is_new      
    end
    @message_displayer.important{"
IMPORTANT NOTE: cvs commit needed but cannot be automated.
Please do a manual commit by running \"cd #{directory} && cvs commit\"
and using the following commit message \"#{message}\" "}
#    Action.new(@command_runner, directory, "cvs commit").act
  end

  def parse_to_files(message)
    changes = {}
    conflicts = []
    message.scan(/^([M|C|\?|A])\s(.+)$/).each do |match|
      filename = match[1].strip
      modification_flag = match[0]
      is_new =  modification_flag == "?"
      conflicts << filename if modification_flag == "C"
      changes[filename] = is_new
    end
    conflicts.each do |conflict|
      @message_displayer.important {"!! THERE ARE CVS CONFLICT ON #{conflict}"}
    end
    changes
  end

  def get_last_vcs_change directory
    @message_displayer.important {"CVS GET LAST VCS CHANGE NOT IMPLEMENTED! "}
    nil
  end

  def get_vcs_url(directory)
    @message_displayer.important {"CVS get vcs url NOT IMPLEMENTED!"}
    nil
  end

  def type
    "cvs"
  end
end