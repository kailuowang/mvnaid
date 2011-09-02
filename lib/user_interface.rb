class UserInterface
  def confirm msg
    puts "#{msg} Y(es)/N(o)"
    reply = gets
    yes?(reply)
  end

  def yes?(input)
    input.index(/y/i) == 0
  end

  def prompt msg
    puts "#{msg}"
    gets.chop
  end
end