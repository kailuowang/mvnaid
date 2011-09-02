require File.join File.dirname(__FILE__), %w( .. lib array )

describe Array do
  describe "psort" do
    it "should sort projects on topology" do
      legacy_parent = Project.new(:legacy_parent, "")
      webstore_oracle = Project.new(:webstore_oracle, "")
      parent = Project.new(:parent, "")
      trus = Project.new(:trus, "")
      legacy_parent.dependencies << webstore_oracle
      parent = Project.new(:parent, "")
      projects = [legacy_parent, webstore_oracle, trus, parent]
      projects = projects.psort
      (projects.index(webstore_oracle) < projects.index(legacy_parent)).should == true
    end
    it "should not add more related project" do
      legacy_parent = Project.new(:legacy_parent, "")
      webstore_oracle = Project.new(:webstore_oracle, "")
      parent = Project.new(:parent, "")
      trus = Project.new(:trus, "")
      legacy_parent.dependencies << webstore_oracle
      parent = Project.new(:parent, "")
      projects = [legacy_parent, trus, parent]
      projects.psort.length.should == 3

    end
  end
end
