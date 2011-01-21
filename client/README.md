# drib
open source packaging and deployment manager

# Requirements
* Perl v5.8.8
* CPAN module

# Usage: 
	drib [options] command [sub-command] [command-options]

# Install 
1. Download the latest stable build `wget http://drib-pdm.org/download/stable`
2. Untar `tar -xf drib-0.6.21.tar`
3. Move into the drib directory `cd drib/`
4. Configure the environment `./configure`
5. Make `make`
6. Install `make install`

# Commands &amp; Options
	help                Display this message
	install             Install a package from dist
	config              Display or change a drib configuration
	create              Create a package
	dist				Upload a file to dist
	remove              Remove an installed package
	set                 Update a package setting
	unset               Remove a package setting
	list                Show a list of installed packages
	build				Run a build manifest
	deploy				Deploy a manifest

	Options:
	 -h, --help         Show this message
	 -v, --version      Version of drib

For more information about a command, run `drib help <command>`

# Contribute
Feel free to fork and hack away. [How to submit your patches](http://dev.drib-pdm.org/contribute)

# Get Help
* IRC: [#dribpdm](irc://irc.oftc.net/#dribpdm)
* Mailing List: [drib-pdm@googlegroups.com](http://groups.google.com/group/drib-pdm)
* Bugs: [github issues](https://github.com/traviskuhl/drib/issues)

# LICENSE

The MIT License

Copyright (c) 2010 Travis Kuhl travis@kuhl.co

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.