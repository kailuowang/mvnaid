=====================================
WHY NEED A BUILD SCRIPT
=====================================
Manual build/check-out/check-in processes are tedious, error-prone, and time-wasting. 
It's hard to have a unified manual process followed by every team member. It may be documented somewhere, but people tend to stray away from tedious, but correct practice. Different people may have different understanding of the processes. As a result, such manual process is hard to change or extend with new better practices.

=====================================
INSTALLATION
=====================================
1, Extract the package somewhere in the project.
2, Each team can has its own profile folder with all the config yml files in it.
    In the team_profiles folder each sub-folder represents one team profile.
    The folder name specified in the team_profile.properties profile=XXXXXXX will be used by the script
    A profile folder consists of several yaml files. Check and(or) edit the yml files where project information is stored
    * Projects local path, vcs settings and dependencies are defined in project_info.yml, this is the main table for projects.
    * Projects deploy info are defined in project_deploy_info.yml
    * most of the dev specific settings are in the build.properties (check the build.properties.template for example)
   This script will silently ignore a project if it's not found on local file system -- this is for the sake of sharing the same project_directories file.

3, If you don't have ruby 1.9 and ruby gems, you need to install them (for windows users please see bottom of this file for detail)
4, Install 2 ruby gems: OptionParser and rspec (optional for testing) (again, for windows users check the bottom part of this file)
5, RSA key for SSH. For any ssh related task, a RSA key has to be uploaded to the server, here is a guide.
http://www.lesbell.com.au/Home.nsf/b8ec57204f60dfcb4a2568c60014ed0f/04eaff076bce249dca256fb6007f53e5?OpenDocument, you can read the part from "Creating an RSA key for SSH v2 Protocol"
6, Create and edit a build.properties file in this script folder, you can copy from the build.properties.template or build.properties.windows_template. Windows users -- use Windows/DOS path syntax for defining m2_repository, even if you will be using Cygwin to run.
7, Confirm or setup a command-line scp. For Windows, if you use Cygwin, an scp is already available. For Windows cmd environment, you can install winscp or others (e.g. Putty has one, named pscp.exe).

====================================
USAGE
====================================
Now you can run the script from the root of the project.
From Windows cmd:
"ruby PATH_TO_SCRIPT\build.rb -h"
The above command will give you the help info.
PATH_TO_SCRIPT is the path from your project root to where your build.rb is
For Cygwin users, you can run as with Windows, using unix path syntax. Using Cygwin simplifies setup, since Cygwin already has a command-line scp available.
For linux/mac users, you can chmod and run build.rb directly.


=====================================
MAJOR FEATURES
=====================================
* build projects - build projects (and their dependent, direct or indirectly, projects if modified) in a dependency order
* run jetty - build all modified projects in a dependency order and then run jetty
* update all projects - svn update all projects in a dependency order and, if something is updated, rebuild the project
* commit all locally change projects - it will do the following
   ** ask for commit message
   ** check all changed projects,
   ** if there are new files,  ask for permission to add them
   ** test (and install) all projects that are dependent(direct or indirectly) on those locally changed projects (It will not install the ones that nobody is dependent on)
   ** add the new files(if there is any) and commit
   (it won't continue if any of the steps fails)
* deploy projects to sandbox(remote or local), (for windows you need to install winscp for remote deployment) this will
   ** build necessary projects
   ** copy jars and presentation artifacts (jsp, js, etc. ) to the sandbox
   ** restart the server if any jar files are copied
   The settings are in the build.properties file and the project_deploy_info.yml file in the team profile. To deploy in a local sandbox, make sure you do not have a "server" entry in the build.properties.
  Deploy requires RSA key deployed on sandbox see below for more info.
* checkout all projects from svn
* save all existing projects' svn urls to a yml file so that new developer can use the checkout feature to load the exact same branches of projects
* remoteclean which mostly is only working for cvs jsp projects now, it will go to the server and remove all locally changed files there and do a cvs update there. 

=====================================
UNDER THE HOOD
=====================================
This script builds modules based on dependency sequence and modification time.
It finds out all projects upon which the targe project is dependent on (direct or indirectly).
It checks both last local change and last svn change against the last recorded time when the script builds it.
For local change, the script does a "svn st" and if there are changed files, the script check the modification time.
For svn change, the script does a "svn info" and checks the last change date
If there is change (local or svn) later than the last recorded build time, the script will build the module.


=====================================
KNOWN ISSUES
=====================================
In the following scenario, the script might not detect a necessary build:
A "svn up" was manually performed(not by the script),  some svn change got pulled in. The svn change is earlier than the last recorded time the script built it.
In this case, you have two options
1) do a "build.rb --clean", so that the build script will forget all build time and therefore re-build everything.
2) do a "build.rb --pushback 9" to set the recorded build time 9(you can set any number) hour earlier. If you push it back to the last time you updated, you shall be fine.


=====================================
TESTING
=====================================
To run tests, you will need to install gem rspec
Run "spec ." to run all tests
Run "spec -h" for help on running specific test

=====================================
INSTALL RUBY AND RUBY GEMS ON WINDOWS
=====================================
1, install ruby
download and run http://rubyforge.org/frs/download.php/69035/rubyinstaller-1.9.1-p378-rc2.exe
In command line run "ruby -v" you should be able to see the version, if not you might need to add ruby bin folder to PATH

2, install ruby gems
download and extract http://rubyforge.org/frs/?group_id=126&release_id=42796 
from the command line go to the folder you just extract the gem package and run the following
  ruby setup.rb
  gem update --system

3, install OptionParser and rspec
from command line, run
  gem install OptionParser
  gem install rspec

=====================================
RSA key for SSH
=====================================
For any ssh related task, a RSA key has to be uploaded to the server, here is a guide.
http://www.lesbell.com.au/Home.nsf/b8ec57204f60dfcb4a2568c60014ed0f/04eaff076bce249dca256fb6007f53e5?OpenDocument, you can read the part from "Creating an RSA key for SSH v2 Protocol"

