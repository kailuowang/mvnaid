require_relative "modification_status_checker"
require_relative "array"

class Project

  attr_reader :name
  attr_reader :directory
  attr_reader :dependencies
  attr_reader :modification_status_checker
  attr_accessor :build_time
  attr_accessor :deploy_time
  attr_accessor :vcs_url
  attr_accessor :vcs_adaptor
  attr_accessor :deployer

  def initialize name, directory, params = {}
    @build_time, @deploy_time, @vcs_url = nil, nil, nil
    @local =  params.has_key?(:local) ? params[:local] : true
    @name = name
    @directory = directory
    @dependencies = []
    @vcs_adaptor = params[:vcs_adaptor]
    @modification_status_checker = params[:modification_status_checker]
    @file_system = params[:file_system]
    @logger = params[:logger]
    @deployer = params[:deployer]
  end

  def dependent_on?(other)
    return true if @dependencies.index(other) != nil

    @dependencies.each do |dependent_project|
      return true if dependent_project.dependent_on?(other)
    end
    false
  end

  def modification_time
    @mtime ||= @modification_status_checker.get_last_change(self) unless @modification_status_checker.nil?
  end

  def inspect()
    @name
  end

  def build_pending?
    return false unless local? and eligible_for_build?
    modified_after? @build_time
  end

  def deploy_pending?
    return false if @deployer.nil?
    return modified_after? @deploy_time
  end

  def modified_after? time
    m_time = modification_time
    return false if m_time.nil?
    return true if time.nil?
    return m_time > time
  end

  def local?
    @local
  end

  def vcs_update
    @vcs_adaptor.update(@directory)
  end

  def vcs_checkout
    @vcs_adaptor.checkout(@vcs_url, @directory) unless @vcs_url.nil?
  end

  def vcs_commit(message)
    local_changes = get_local_changes
    return if local_changes.size == 0
    @vcs_adaptor.commit_with_local_changes(local_changes, @directory, message)
  end

  def get_vcs_change             
    @vcs_adaptor.get_last_vcs_change(@directory)
  end

  def get_local_changes
    @local_change ||= @vcs_adaptor.get_local_changes(@directory)
  end

  def get_local_changed_files
    get_local_changes().keys
  end

  def get_possibly_modified_files

    possible_reverted_files = get_local_changed_files_when_last_deploy.select {|file| @file_system.exists? file}

    Set.new(get_local_changed_files).merge(possible_reverted_files).to_a
  end

  def project_log
    @logger.get_log(@name) if @logger
  end

  def get_local_changed_files_when_last_deploy
    (project_log[:local_changed_files_when_last_deploy] if project_log) || []
  end

  def get_new_files
     get_local_changes.reject { |key,value| !value }.keys
  end

  def update_vcs_url
    new_url =@vcs_adaptor.get_vcs_url(@directory)
    changed = !new_url.nil? && new_url != @vcs_url
    @vcs_url = new_url if changed
    changed
  end
  
  def deploy
    result = @deployer.deploy
    project_log[:local_changed_files_when_last_deploy] = get_local_changed_files if project_log
    @deploy_time = Time.now
    result
  end

  def eligible_for_build?
    @file_system.exists?(File.join(@directory, "pom.xml")) 
  end

  def dependencies_string
    string = ""
    @dependencies.each { |dependency| string <<  "\n    - " << dependency.name }
    string = ":dependencies: " << string if string.length > 0
    string
  end

  def to_s()
"
#{@name}:
  :vcs_url: #{@vcs_url}
  :vcs_type: #{@vcs_adaptor.type if @vcs_adaptor}
  :local_path: #{@directory}
  #{dependencies_string}
"
  end

end