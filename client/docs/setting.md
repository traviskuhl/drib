# Settings
Set a package variable

## Usage
	drib set <project>/<package> <key>=<value> ...
	drib unset  <project>/<package> <key>=<value> ... 
	
### Description

* **drib set `<project>/<package> <key>=<value> ...`**: Setting will be applied only to specified package. You can
	escape `values` using single or double quotes. Settings can have empty values `<key>=`
	
* **drib unset `<project>/<package> <key>=<value> ...`**: Settings will be applied only to specified package.