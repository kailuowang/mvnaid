require File.join File.dirname(__FILE__), %w(.. command_runner)
require File.join File.dirname(__FILE__), %w(.. util)

class Action
  include Util
  def initialize(command_runner, location, command, options ={})
    @command_runner = command_runner
    @directory = (location.respond_to? :directory) ? location.directory : location
    @directory = path(@directory) unless @command_runner.is_a? RemoteCommandRunner
    @command = command
    @options = options
  end

  def act
    return unless valid?
    dir = @directory.include?(" ") ? "\"#{@directory}\"" : @directory
    command_output = @command_runner.run("cd #{dir} && #{@command}", @options)
    post_act
    return command_output
  end

  def valid?
    return true
  end

  def post_act
    #implment this in subclass if necessary
  end
end