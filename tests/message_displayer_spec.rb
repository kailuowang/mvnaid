require File.join File.dirname(__FILE__), %w(.. lib message_displayer)

describe MessageDisplayer do
  describe "trivial" do
    it "should not evaluate expression if it's not in verbose mode" do
      object = mock(:someobj)
      object.should_not_receive(:to_s)
      MessageDisplayer.new(false).trivial { object.to_s }
    end
  end
  describe "important" do
    it "should not evaluate expression if it's in quiet mode" do
      object = mock(:someobj)
      object.should_not_receive(:to_s)
      MessageDisplayer.new(false, true).important { object.to_s }
    end
  end

end