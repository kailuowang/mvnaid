require_relative "message_displayer"

class CommandRunner
  attr_reader :message_displayer
  
  def initialize debug = false, message_displayer = MessageDisplayer.new
    @debug = debug
    @message_displayer = message_displayer
  end

  def run command, options = {}
    @message_displayer.command {"#{command}"}
    display_output = options[:display_output] || @message_displayer.verbose
    command_output, success = do_command(command, display_output)
    if (!success && !options[:ignore_error])
      @message_displayer.output {command_output} unless display_output
      throw("FAILED COMMAND #{command}")
    end
    command_output
  end

  private
  def do_command(command, display_output)
    command_output = ""
    dot_print = false
    IO.popen("#{command} 2>&1") do |f|
      f.each_line do |line|
        if display_output
          @message_displayer.output {line}
        else
          print '.'
          dot_print = true
        end
        command_output << line
      end
    end unless @debug
    puts "" if dot_print
    return command_output, (@debug ? true : $?.success?)
  end
end