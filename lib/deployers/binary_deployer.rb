require File.join File.dirname(__FILE__), %w(.. jobs scp_action)
require File.join File.dirname(__FILE__), %w(.. jobs build_action)

class BinaryDeployer
  attr_reader :project
  attr_reader :project_repo

  def initialize(params)
    @project = params[:project]
    @command_runner = params[:command_runner]
    @destination_username = params[:destination_username]
    @destination_path = params[:destination_path]
    @server = params[:server]
    binary_paths = params[:binary_file_path]
    binary_paths = [binary_paths] unless !binary_paths.nil? && binary_paths.is_a?(Array)  
    @binary_file_paths = binary_paths
    @project_repo = params[:project_repo]
  end

  def deploy
     build if @project.build_pending?
     @binary_file_paths.each {|p| scp_binaries(p) }
     true
  end

  def build
    BuildAction.new(@command_runner, @project, @project_repo).act
  end

  private
  
  def scp_binaries(p)
    cp_action(p).act
  end

  def cp_action binary_file_path
    paths = File.split(binary_file_path)
    directory = paths[0]
    file = paths[1]
    if(@server)
      ScpAction.new(command_runner: @command_runner,
                  source: file,
                  directory: directory,
                  destination_path: @destination_path,
                  server: @server,
                  username: @destination_username)
    else
      Action.new(@command_runner, directory, "cp #{file} #{@destination_path}")
    end

  end

  def to_s
    "Binary Deployer"
  end
end