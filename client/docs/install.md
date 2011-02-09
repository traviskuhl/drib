# Install
Install a package from a local command or remote repository

## Usage
	drib install <command> <options>

## Commands
	drib install <project>/<package>
	drib install <project>/<package>-<branch>
	drib install <project>/<package>-<version>
	drib install <repo>:<project>/<package>-<version>
	drib install <gzip tarball file>

### Description
* **drib install `<project>/<package>`**:
	Install the current branch of a package from the default dist repository. If
	project is not given, default project is used. 
	
	
* **drib install `<project>/<package>-<branch>`**:
	Install a package from given branch from the default dist repoistory. The command
	variable overrides the `--branch` option

* **drib install `<project>/<package>-<version>`**:
	Install the given version of a package from teh default dist repository. The command 
	variable overrides the `--version` and `--branch` option
	
* **drib install `<repo>:<project>/<package>-<version>`**:
	Install a given package from given dist repository. The command veriable overrides the 
	`--repo` option

* **drib install `<gzip tarball file>`**:
	Installs a package from the given tarball file. No matter what folder the command is run
	from, installs are always relative to the folder the package file is in. Use the `--type=symlink` option 
	to symlink the package install

## Options

* `--project=<project>` `-p <project>`: specify project to install to

* `--cleanup` `-c`: remove the tar file after install is complete

* `--version=<version>` `-v <version>`: install the given version

* `--branch=<branch>` `-b <branch>`: install from a given branch

* `--same` `-s`: override the install of the same version as currently installed

* `--downgrade` `-d`: override the downgrade install of the currently installed package

* `--depend` `-dep`: skip depency checks

* `--repo=<rep>` `-r <repo>`: install from given repo

