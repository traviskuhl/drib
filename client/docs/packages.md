# Packages
Packages are bundels of code and configuration settings compressed into a gzipped tarball. Packages are generated using a package file.

## Package Files
Package files tell drib how to build your package. The most common format for a package file is the 
`Drib Pacakge File Format` (yes i total made that up) or DPF. Out of the box, drib also supports 
JSON and Perl package files. drib uses the file extension to determine which parser to use on the package file. 
Here's a list of default package file parsers:
 
 * **Drib Package File Format** .dpf (Parser: `Drib::Parsers::Text`)
 * **Perl** .pkg (Parser: `Drib::Parsers::Perl`) _mostly depreciated_

## Example Package File
	# fe.dpf -- 2010-05-14		
	
	# internal variables
	src = ../src
	htdocs = /home/bolt/share/htdocs/wot/fe
	pear = /home/bolt/share/pear/wot/fe
	conf = /home/bolt/conf/httpd/
	assets = /home/bolt/share/htdocs/assets/wot
	
	# meta data
	meta project = wot
	meta name = fe
	meta version = file:./changelog
	meta summary = Front End
	meta description = wot Front End
	meta changelog = ./changelog
	
	# settings
	set host waroftruth.com
	set port 80
	set listen
	set dbhost localhost
	
	# directorys
	dir - - - $(htdocs)
	dir - - - $(pear)
	dir - - - $(conf)
	dir - - - $(assets)
	
	# assets
	find - - - $(assets) $(src)/assets/ -depth -name "*.*"
	
	# pear
	find - - - $(pear)	$(src)/ -depth -name "*.php" 
	
	# class
	find - - - $(pear) $(src)/ -depth -name "*.class.php"
	
	# set our conf file
	settings $(conf)	../conf/wot_fe.conf
	
	# post install
	command post-install /etc/init.d/httpd restart
	command post-set /etc/init.d/httpd restart
	
## Parts of a Package File
Below is mostly cover the Drib Package Format. While most commands translate to the Perl parser, I'm not going to go into detail about the Perl parser here.

### Meta Data
Defines information about the package.

 * **meta project** (required) Name of the project this package belongs to
 * **meta name** (required) Name of the package
 * **meta version** (required) Version number of the project. You can also prefix with `file:<file_path>` and drib will read the version from the given file using the regex `/Version ([0-9\.]+)/i`
 * **meta summary** (required) Short summary of the package
 * **meat description** Long summary of the package
 * **mate changelog** Path to the changelog file 

### Package Variables
Package variables allow you to define variables that are globaly replaced in the package file. Package variables are not available outside of the package.

 * **Example:** `src = ../`
 * **Format:** `key = value`
 * **Allowed Key Characters:** `[a-zA-Z0-9\_]+`
 * **Replacement:** `$(key)`
 * **Default:** `$(key|<default value>)` _default value can not contain a closing parentheses_
 
You can set or override package variables at create time by using the `--var key=value` command argument
 

### Dependencies 
Specify packages that must exist before the package can be installed.

 * **Example:** `depend project/package 1.0 9.0` 
 * **Format:** `depend <package> <min_version> <max_version>`

### Settings

#### Package Settings
Create package settings.

 * **Example:** `set host example.com`
 * **Format:** `set <name> <value>`
 * **Allowed Name Characters:** `[a-zA-Z0-9\_]+` 

#### Settings Files

### Directory
Specify a directory to be created in the package

 * **Example:** `dir - - 755 /home/bolt`
 * **Format:** `dir <user> <group> <permission> <path>`

### File
Specify files that should be created in the package
 
 * **Example:** `file - - 755 ./hello.html /home/bolt/share/htdocs`
 * **Format:** `file <user> <group> <permission> <dest> <src>`
    * **src** path to file
    * **dest** path to folder`src` file should be placed in

### Find
Execute a find to specify files that should be create in the package

 
 * **Example:** `find - - 755 ./hello /home/bolt/share/htdocs`
 * **Format:** `find <user> <group> <permission> <dest> <src> <find_command>`
    * **dest** path to folder matched files should be moved
    * **src** path to run find command on
    * **find_command** find command arguments


### Commands
Commands to run when specific event happens

 * **Example** `command post-install /etc/init.d/httpd restart`
 * **Format** `command <event> <command>`

#### Events
 * post-install - run after each install is complete
 * pre-install - run before each install starts
 * post-set - run after a drib `set` command is run
 * pre-set - run before a drib `set` command is run
 * start - run when a drib `start` command is run
 * stop - run when a drib `stop` command is run
