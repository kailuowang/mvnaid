require 'optparse'
require 'optparse/time'
require 'ostruct'
require_relative "version"

class OptionParser

  def self.show_readme
    File.open(File.join(File.dirname(__FILE__), "..", "readme.txt"), "r") do |f|
      while (line = f.gets)
        puts line
      end
    end
  end

  def self.parse(args)
    options = OpenStruct.new
    options.build_project_names = []
    options.jetty_run_project_name = nil
    options.verbose = false
    options.quiet = false
    options.clean = false
    options.commit = false
    options.checkout = false
    options.get_svn_urls = false
    options.deploy = false
    options.update = false
    options.info = false
    options.local_changes = false
    options.remote_clean = false
    options.restart = false
    options.build_all = false
    options.push_back_build_time = nil

    opts = OptionParser.new do |opts|
      opts.separator "check manual (-m) for more details"
      opts.banner = "Usage: build.rb [options]"

      opts.separator ""
      opts.separator "operations:"
      opts.separator ""
      opts.separator "default(no options) is to build all oustanding projects"
      opts.separator ""

      opts.on("-u", "--update", "svn update all projects and build the ones that get updated") do |u|
        options.update = u
      end

      build_option_notes = "build projects(no space between project names) and all modified dependencies"
      opts.on("-b", "--build project1,project2", Array, build_option_notes) do |list|
        options.build_project_names = list
      end

      opts.on("-r","--runjetty jetty_project", "run jetty on a project and build all modified dependencies") do |r|
        options.jetty_run_project_name = r
      end

      opts.on( "--clean", "clean build log(will force rebuild everything)") do |c|
        options.clean = c
      end

      opts.on("--commit", "commit all changes to svn(check readme.txt for details)") do |c|
        options.commit = c
      end

      opts.on("--restart", "restart sandbox server") do |c|
        options.restart = c
      end

      opts.on("--info", "list all projects with detailed info") do |c|
        options.info = c
      end
      opts.on("--localchanges", "list all local changes in all projects") do |c|
        options.local_changes = c
      end

      opts.on("--checkout", "checkout out all projects from svn to local (svn co)") do |c|
        options.checkout = c
      end

      opts.on("--deploy", "deploy modified projects (RSA key needed, please see manual)") do |c|
        options.deploy = c
      end

      opts.on("--remoteclean", "clean the remote files on sandbox") do |c|
        options.remote_clean = c
      end

      opts.on("--build-all", "force building all projects") do |b|
        options.build_all = b
      end

      opts.separator ""
      opts.separator "general options:"

      opts.on("-v", "--[no-]verbose", "output verbosely") do |v|
        options.verbose = v
      end

      opts.on("-q", "--[no-]quiet", "be quiet") do |q|
        options.quiet = q
      end


      opts.separator ""
      opts.separator "special operations:"

      opts.on("--pushback N", Integer, "RARELY NEEDED, ONLY AFTER YOU DID A MANUAL SVN UP and get updates older than last build time. It push back the build time for N hours to force build projects with early svn change time") do |n|
        options.push_back_build_time = n
      end

      opts.separator ""
      opts.separator "Info options:"

      opts.on_tail("-h", "--help", "Show this message") do
        puts opts
        exit
      end

      opts.on_tail("-m", "--manual", "Show manual(readme.txt)") do
        show_readme()
        exit
      end

      opts.on_tail("--version", "Show version") do
        puts CURRENT_VERSION
        exit
      end
    end

    opts.parse!(args)
    options
  end
end