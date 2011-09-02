require_relative "user_interface"
require_relative "util"

class CommitMessageBuilder
  include Util

  def initialize user_interface, answers_file_path = nil
    @user_interface = user_interface
    @answers_file_path = answers_file_path
    @answers = load_yaml_hash(answers_file_path)
  end

  def prompt msg
    remembered_msg = @answers.has_key?(msg)
    prompt_msg = remembered_msg ? msg + " (default: \"#{@answers[msg]}\")" : msg
    answer = @user_interface.prompt(prompt_msg)
    answer = @answers[msg] if ( answer.empty? && remembered_msg )
    @answers[msg] = answer
    save_yaml(@answers_file_path, @answers) unless @answers_file_path.nil?
    return answer
  end

  def build_pair_names
    pair_name = prompt("Who is your pair?")
    dev_name = prompt("Who are you?")
    return "[#{pair_name}/#{dev_name}]"
  end

  def build_issue_key
    project = prompt("What's the project name?")
    issue_number = prompt("What's the issue number?")
    return "#{project}-#{issue_number}"
  end

  def build
    build_issue_key << " " << build_pair_names << " " << prompt("What did you guys do?")
  end

end