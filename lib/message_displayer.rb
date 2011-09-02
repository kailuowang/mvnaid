class MessageDisplayer
  attr_reader :verbose
  attr_reader :quiet
  def initialize verbose = false, quiet = true
    @verbose = verbose
    @quiet = quiet
  end

  def trivial &b
    display_formatted_message &b if @verbose
  end

  def important &b
    display_formatted_message &b
  end

  alias scream important

  def output prefix = '', &b
    puts prefix + b.call unless @quiet
  end

  def command &b
   output "COMMAND: ", &b
  end

  private
  def display_formatted_message &b
   output "\# ", &b
  end
end