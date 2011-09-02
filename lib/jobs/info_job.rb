class InfoJob
   def initialize project_repo, message_displayer = MessageDisplayer.new
    @project_repo = project_repo
    @message_displayer = message_displayer
  end
  def run
    @project_repo.all_projects.each do |p|
      p.update_vcs_url if p.local?
      @message_displayer.output { p.to_s }
    end
    @project_repo.validate_dependencies_order
  end
end