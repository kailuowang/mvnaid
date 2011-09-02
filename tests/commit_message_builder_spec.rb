require File.join File.dirname(__FILE__), %w(.. lib commit_message_builder)


describe CommitMessageBuilder do
  describe "build_pair_names" do
    it "should prompt to ask pair and dev name" do
      user_interface = mock(:user_interface)
      a_dev_name = "Carl"
      a_pair_name = "Scott"
      user_interface.should_receive(:prompt).and_return(a_pair_name)
      user_interface.should_receive(:prompt).and_return(a_dev_name)
      CommitMessageBuilder.new(user_interface).build_pair_names.include?("[#{a_pair_name}/#{a_dev_name}]").should == true
    end
  end
  describe "build_issue_key" do
    it "should prompt to ask project name and issue number" do
      user_interface = mock(:user_interface)
      project_name = "thoughtdocs"
      issue_number = "182"
      user_interface.should_receive(:prompt).and_return(project_name)
      user_interface.should_receive(:prompt).and_return(issue_number)
      CommitMessageBuilder.new(user_interface).build_issue_key.include?("#{project_name}-#{issue_number}").should == true      
    end
  end

  describe "build" do
    it "should build the message" do
      user_interface = mock(:user_interface)
      a_dev_name = "Carl"
      a_pair_name = "Scott"
      project_name = "thoughtdocs"
      issue_number = "182"
      message = "added some file"
      user_interface.should_receive(:prompt).and_return(project_name)
      user_interface.should_receive(:prompt).and_return(issue_number)
      user_interface.should_receive(:prompt).and_return(a_pair_name)
      user_interface.should_receive(:prompt).and_return(a_dev_name)
      user_interface.should_receive(:prompt).and_return(message)
      expected_message =  "#{project_name}-#{issue_number} [#{a_pair_name}/#{a_dev_name}] #{message}"
      CommitMessageBuilder.new(user_interface).build().should == expected_message      
    end
  end

  describe "prompt" do
    before(:each) do
      @answer_log_file = "prompt_answers.yml"
    end

    it "should remember prompt question put it in the message" do
      a_question = "What's the name of you first pet?"
      an_answer = "Bob"
      user_interface = mock(:user_interface)
      user_interface.should_receive(:prompt).with(a_question).and_return(an_answer)
      user_interface.should_receive(:prompt).with("#{a_question} (default: \"#{an_answer}\")").and_return("")
      commit_message_builder = CommitMessageBuilder.new(user_interface)
      commit_message_builder.prompt(a_question)
      commit_message_builder.prompt(a_question).should == an_answer
    end

    it "should remember answers in file" do
      a_question = "What's the name of you first pet?"
      an_answer = "Bob"
      user_interface = mock(:user_interface)
      user_interface.should_receive(:prompt).with(a_question).and_return(an_answer)
      commit_message_builder = CommitMessageBuilder.new(user_interface, @answer_log_file)
      commit_message_builder.prompt(a_question)

      user_interface2 = mock(:user_interface2)

      user_interface2.should_receive(:prompt).with("#{a_question} (default: \"#{an_answer}\")").and_return("")
      commit_message_builder = CommitMessageBuilder.new(user_interface2, @answer_log_file)
      commit_message_builder.prompt(a_question).should == an_answer
    end

    after(:each) do
      File.delete(@answer_log_file) if File.exist?(@answer_log_file)
    end

  end
end

