require File.join File.dirname(__FILE__), %w(.. remote_command_runner)

class RemoteDeployer

  def initialize(params)
    @remote_command_runner = RemoteCommandRunner.new(params[:command_runner],params[:server], params[:username])
    @remote_location = params[:remote_location]
    @restart_script = params[:restart_script]
  end

  def remote_update
    stop_server_script = "#{@restart_script} stop && " if @restart_script
    @remote_command_runner.run( "#{stop_server_script}cd #{@remote_location} && svn up && mvn clean install", {in_background: true})
  end

  def deploy
    false
  end

  def to_s
    "Remote Deployer"
  end
end