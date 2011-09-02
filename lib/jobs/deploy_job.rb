require File.join File.dirname(__FILE__), %w(.. project_repo)
require File.join File.dirname(__FILE__), %w(.. message_displayer)
require File.join File.dirname(__FILE__), %w(.. remote_command_runner)

class DeployJob
  attr_reader :command_runner
  def initialize project_repo, command_runner, message_displayer = MessageDisplayer.new
    @project_repo = project_repo
    @message_displayer = message_displayer
    @restart_script = @project_repo.default_deploy_info[:restart_script_path]

    server = @project_repo.default_deploy_info[:server]
    if @restart_script
      @command_runner = server ? RemoteCommandRunner.new(command_runner,
                                                server,
                                                @project_repo.default_deploy_info[:username]) :
                                 command_runner
    end
  end

  def run
    @message_displayer.important {"Start to deploy projects"}
    restart_needed_results =
      @project_repo.all_projects.collect do |project|
        @message_displayer.important {"checking project #{project.name} (deployer: #{project.deployer})for deploy..."}
        if project.local?
          deploy(project)
        else
          @message_displayer.scream {"Project #{project.name} is missing in local. Please check it out using build.rb --checkout "}
        end
      end
    restart_sandbox if restart_needed_results.any?
    @project_repo.persist_project_logs
  end

  def restart_sandbox
    if @restart_script.nil?
      @message_displayer.important {"restart script not found, please set it in build.properties."}
      return
    end
    @message_displayer.important {"Restarting Server"}
    @command_runner.run(@restart_script)
    @message_displayer.important {%(to see the log run "ssh #{@command_runner.user}@#{@command_runner.server} 'tail -f ~/mvc.log'")}
  end

  private
  def deploy(project)
    if project.deploy_pending?
      project.deploy
    else
      @message_displayer.trivial { "project #{project.name} deploy not needed. Last deploy time: #{project.deploy_time} Last modification time: #{project.modification_time}" }
    end
  end

end

