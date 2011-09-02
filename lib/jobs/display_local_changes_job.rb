class DisplayLocalChangesJob
  def initialize project_repo, message_displayer
    @project_repo = project_repo
    @message_displayer = message_displayer
  end

  def run
    messages = []
    @project_repo.all_projects.each do |project|
      local_changes = project.get_local_changes
      messages << "#{project.name} changes" unless local_changes.empty?
      local_changes.each do |file,new|
        modifier = new ? "?" : "m"
        messages << "#{modifier} #{file}"
      end
    end
    if !messages.empty?
      @message_displayer.important{"***CHANGES FOUND!!***"} unless messages.empty?
      messages.each {|m| @message_displayer.important {m}}
    else
      @message_displayer.important{"***NO LOCAL CHANGES***"}
    end

  end
end