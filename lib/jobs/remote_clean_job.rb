class RemoteCleanJob
  def initialize project_repo, message_displayer = MessageDisplayer.new
    @project_repo = project_repo
    @message_displayer = message_displayer
  end

  def run
    @project_repo.all_projects.each do |project|
      project.deployer.remote_clean if project.deployer != nil and project.deployer.respond_to? :remote_clean
    end
  end
end