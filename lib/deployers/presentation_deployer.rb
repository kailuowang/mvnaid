require File.join File.dirname(__FILE__), %w(.. jobs scp_action)
require File.join File.dirname(__FILE__), %w(.. remote_command_runner)
require File.join File.dirname(__FILE__), %w(.. command_runner)

class PresentationDeployer
  attr_reader :destination_path

  def initialize(params = {})
    @project = params[:project]
    params[:command_runner] ||= CommandRunner.new
    @remote_command_runner = RemoteCommandRunner.new(params[:command_runner], params[:server], params[:destination_username])
    @destination_path = params[:destination_path]
    @remote_post_update_command = params[:remote_post_update_command]
  end

  def deploy
    @project.get_possibly_modified_files.each do |file|
      scp_action(file).act
    end
    restart_needed = false
  end

  def remote_update
    update_command = @project.vcs_adaptor.update_command
    remote_command =  " && #{@remote_post_update_command}" if @remote_post_update_command
    Action.new(@remote_command_runner, @destination_path, "#{update_command}#{remote_command}" , {in_background: true}).act
  end

  def remote_clean
    @project.vcs_adaptor.get_local_changes(@destination_path, @remote_command_runner).each do |file, new|
      remove_remote_file(file) unless new
    end
    remote_update
  end

  def to_s
    "Presentation Deployer"
  end

  private
  def scp_action(file)
     ScpAction.new(source: file,
                   directory: @project.directory,
                   destination_path: @destination_path,
                   server: @remote_command_runner.server,
                   command_runner: @remote_command_runner.command_runner,
                   username: @remote_command_runner.user)
  end


  def remove_remote_file(file)
    Action.new(@remote_command_runner, @destination_path, "rm #{file}").act
  end

end                  