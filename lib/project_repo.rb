require_relative "project"
require_relative "util"
require File.join File.dirname(__FILE__), "vcs_adaptors", "cvs_adaptor"
require File.join File.dirname(__FILE__), "vcs_adaptors", "svn_adaptor"
require File.join File.dirname(__FILE__), "vcs_adaptors", "git_svn_adaptor"
require File.join File.dirname(__FILE__), "vcs_adaptors", "git_adaptor"
require File.join File.dirname(__FILE__), "vcs_adaptors", "vcs_adaptor_factory"
require File.join File.dirname(__FILE__), "deployers", "deployer_factory"
require File.join File.dirname(__FILE__), "deployers", "presentation_deployer"
require File.join File.dirname(__FILE__), "deployers", "binary_deployer"
require File.join File.dirname(__FILE__), "deployers", "remote_deployer"
require "set"

class ProjectRepo
  include Util
  def initialize params = {}
    @projects_info_file_path = params[:projects_info_file_path]
    @projects_info = params[:projects_info] || load_yaml_hash(params[:projects_info_file_path])
    @project_directories = params[:project_directories] || load_project_directories(@projects_info)
    @project_deploy_info = params[:project_deploy_info] || load_yaml_hash(params[:deploy_info_file_path])
    @build_properties = params[:build_properties] || {}
    @file_system = params[:file_system] || FileSystem.new
    @modification_status_checker = params[:modification_status_checker] || ModificationStatusChecker.new(file_system: @file_system)

    @projects = {}
    params[:projects].each do |project|
      raise "project name #{project.name} already exists!!" if @projects.has_key?(project.name)
      @projects[project.name] = project
    end unless params[:projects].nil?

    @command_runner = params[:command_runner]
    @message_displayer = params[:message_displayer] || MessageDisplayer.new

    @project_log_file_path = params[:build_log_file_path]
    @project_logs = params[:build_log] || load_yaml_hash(@project_log_file_path)
    unless(@project_deploy_info.nil? or @project_deploy_info.empty?)
      @deployer_factory = DeployerFactory.new(@project_deploy_info.merge(build_properties: @build_properties,
                                                                         command_runner: @command_runner,
                                                                         message_displayer: @message_displayer,
                                                                         project_repo: self));

    end
    @vcs_adaptor_factory = params[:vcs_adaptor_factory] || VcsAdaptorFactory.new(@command_runner,
                                                                                 @build_properties[:default_vcs_type],
                                                                                 @build_properties[:username],
                                                                                 @message_displayer)
  end

  def get(project_name)
    return @projects[project_name] if @projects.has_key? project_name
    if @project_directories.has_key? project_name
      create_project(project_name)
    else
      raise "#{project_name } not found in the repo"
    end
  end

  def update_build_deploy_times_in_project_logs
    @projects.each_value do |project|
      log = get_log(project.name)
      log[:build_time] = project.build_time
      log[:deploy_time] = project.deploy_time
    end
    return @project_logs
  end

  def persist_project_logs
    return if @project_log_file_path.nil?
    update_build_deploy_times_in_project_logs
    save_yaml(@project_log_file_path, @project_logs)
  end

  def clean_project_log
    all_projects.each{|project| project.build_time, project.deploy_time = nil, nil}
    persist_project_logs
  end

  def push_back_build_time(hours)
    all_projects.each do |project|
      project.build_time = project.build_time - 3600*hours unless project.build_time.nil?
    end
    persist_project_logs
  end

  def all_projects
    @project_directories.keys.collect do |project_name|
      get(project_name)
    end if @projects.size < @project_directories.size
    @projects.values.psort
  end

  def all_projects_dependent_on(project)
    projects = Set.new
    all_projects.each do |p|
      if p.dependent_on?(project)
        projects.add(p)
        projects.merge(all_projects_dependent_on(p))
      end
    end
    projects
  end

  def save_project_vcs_urls()
    all_projects.each do |p|
      @projects_info[p.name] = {} unless @projects_info.has_key? p.name
      @projects_info[p.name][:vcs_url] = p.vcs_url
    end
    save_yaml(@projects_info_file_path, @projects_info)
  end

  def default_deploy_info
    @deployer_factory ? @deployer_factory.general : {} 
  end

  def create_deployer(project)
    return nil if @deployer_factory.nil?
    return @deployer_factory.create_deployer(project)
  end

  def validate_dependencies_order
    sorted_projects = all_projects
    error_found = false
    sorted_projects.each do |project|
      sorted_projects.each do |other_project|
         if project.dependent_on? other_project and
              sorted_projects.index(project) < sorted_projects.index(other_project)
           @message_displayer.output{"ERROR: dependency order between '#{project.name}' and '#{other_project.name}' is wrong!"}
           error_found = true
         end
      end
    end
    @message_displayer.important {"No dependencies error found."} unless error_found 
  end

  def create_project(project_name)
     directory = @project_directories[project_name]
     project = Project.new(project_name, directory,
                           modification_status_checker: @modification_status_checker,
                           local: @file_system.exists?(directory),
                           file_system: @file_system,
                           logger: self )
     @projects[project_name] = project
     @vcs_adaptor_factory.set_vcs_adaptor(project, @projects_info[project_name])
     project.deployer = create_deployer(project)
     set_dependencies(project)
     set_build_deploy_time(project)
     return project
  end

  def load_project_directories(project_info)
    directories = {}
    project_info.each do |project_name, info|
      directories[project_name] = info[:local_path]
    end
    directories
  end

  def get_log project_name
    @project_logs[project_name] = {} unless @project_logs.has_key? project_name
    @project_logs[project_name]
  end

  private
  def set_dependencies(project)
    if @projects_info.has_key?(project.name) and @projects_info[project.name].has_key?(:dependencies)
      @projects_info[project.name][:dependencies].each do |dependent_project_name|
        project.dependencies << get(dependent_project_name)
      end
    else
      @message_displayer.trivial{"no dependencies for project #{project.name}"}
    end
  end


  def set_build_deploy_time(project)
    if !@project_logs.nil? && @project_logs.has_key?(project.name)
      project.build_time = @project_logs[project.name][:build_time]
      project.deploy_time = @project_logs[project.name][:deploy_time]
    end
  end

end
