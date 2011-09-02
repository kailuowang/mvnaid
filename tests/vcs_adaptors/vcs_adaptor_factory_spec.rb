require File.join File.dirname(__FILE__), %w(.. .. lib vcs_adaptors vcs_adaptor_factory)
require File.join File.dirname(__FILE__), %w(.. .. lib vcs_adaptors svn_adaptor)
require File.join File.dirname(__FILE__), %w(.. .. lib vcs_adaptors git_svn_adaptor)
require File.join File.dirname(__FILE__), %w(.. .. lib vcs_adaptors cvs_adaptor)

describe VcsAdaptorFactory do
  describe "set_vcs_adatpor" do
    it "should set vcs url and create adaptor" do
      project = Project.new(:p1, "")
      vcs_info = {vcs_url: "someurl", vcs_type: :svn}
      factory = VcsAdaptorFactory.new(nil)
      factory.should_receive(:create_vcs_adaptor).with(vcs_info)
      factory.set_vcs_adaptor(project, vcs_info)
      project.vcs_url.should == "someurl"
    end
  end

  describe "create_vcs_adaptor" do
    it "should create svn adaptor" do
      vcs_info = {vcs_type: :svn}
      VcsAdaptorFactory.new(nil).create_vcs_adaptor(vcs_info).should be_a SvnAdaptor
    end
    it "should create git_svn adaptor" do
      vcs_info = {vcs_type: :git_svn}
      VcsAdaptorFactory.new(nil).create_vcs_adaptor(vcs_info).should be_a GitSvnAdaptor
    end
    it "should create cvs adaptor" do
      vcs_info = {vcs_type: :cvs}
      VcsAdaptorFactory.new(nil).create_vcs_adaptor(vcs_info).should be_a CvsAdaptor
    end
    it "should create with adaptor command_runner" do
      command_runner = mock(:command_runner)
      VcsAdaptorFactory.new(command_runner).create_vcs_adaptor({}).command_runner.should == command_runner
    end
  end
end
