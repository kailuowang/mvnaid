require File.join File.dirname(__FILE__), %w(.. lib command_runner)

class MockCommandRunner  < CommandRunner
  attr_reader :commands_run
  attr_reader :verbose

  def initialize(verbose = false)
    @verbose = verbose
  end

  def stub(command, output)
    @stubs ||= {}
    @stubs[command] = output
  end

  def run command, options = {}
    @commands_run ||= []
    @commands_run.push(command)
    puts command if @verbose
    return @stubs[command] unless @stubs.nil?
    return "unstubbed command"
  end

end