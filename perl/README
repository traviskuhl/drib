usage: drib [options] command [sub-command] [command-options]

List of Commands:
 help                Display this message
 self-install        Install the downloaded version of drib
 install             Install a package from dist
 config              Display or change a drib configuration
 create              Create a package
 remove              Remove an installed package
 set                 Update a package setting
 unset               Remove a package setting
 list                Show a list of installed packages

Options:
 -h, --help         Show this message
 -v, --version      Version of drib


--------------------------------------------------------------- 
 Self Install
--------------------------------------------------------------- 
usage: drib self-install [-t type]

    sub commands:   
        none        
    
    options:
        -t, --type=[type]       Install type, see `install` for list of types        


--------------------------------------------------------------- 
 Config
--------------------------------------------------------------- 
usage drib config [key=value ...]

    sub commands:
        key=value   list of key, value conifuration settings
                    to update. leave blank to display list
                    of settings
    
    options:
        none
            
--------------------------------------------------------------- 
 Install
--------------------------------------------------------------- 
usage: drib install <package|package-file> [-v version [-b branch]]  

            'cleanup'=>'cleanup|c',        
            'version'=>'version=s',
            'branch'=>'branch=s',
            'same' => 'same|s',
            'downgrade' => 'downgrade',

    sub commands:
        package         Name of the package. Can also prfix the project and include
                        the version or branch after a dash.
                        ex: default/package, package-version or package-branch
        package-file    Package file (must have been created using drib create)
                        
                        
    options:
        -v, --version=[version]     Version of the package to install
        -b, --branch=[branch]       Branch to install from. (version takes precedence)
        -c, --cleanup               Delete any package files used when creating a file
        -s, --same                  Allow drib to install the same currently installed package
        -d, --downgrade             Allow drib to install an older package than is currently installed
                                        
    example
        drib install tester -v 0.1.1
        drib install tester-1.0.tar.gz        
        drib install default/test-1.0

    alias:
        i, in, inst
                                        
--------------------------------------------------------------- 
 Create
--------------------------------------------------------------- 
usage: drib create <package-manifest> [--no-dist [-b branch [-i install [-t type]]]]


    sub commands:
        package-manifest       Path to the package manifest file
        
    options
        --no-dist                   Do not send package to dist, save in pwd
        -b, --branch=[branch]       Branch to install the package version to
        -i, --install               After package is created, install locally        
        -t, --type=[type]           Build type:
                                        release = does a normal install (default)
                                        beta = beta package with unique version
                                        nightly = nightly package with unique version
                                        symlink = symlinks all files 
        
    example:
        drib create test.pkg -b nightly
        

--------------------------------------------------------------- 
 Set
---------------------------------------------------------------
usage: drib set <package> <name>=<value> [... [--no-files]]

    sub commands
        package             Name of package to update setting
        name                Name of setting to update
        value               Value to assign
        
    options
        --no-files          Do not update any settings files
        
    example
        drib set test port=85 hello=world
        

--------------------------------------------------------------- 
 Unset
---------------------------------------------------------------        
useage: drib unset <package> <name>=<value> [...]  

    sub comamnds
        package 
        
    options
        none
        
    example
        drib unset test port hello
        
--------------------------------------------------------------- 
 List
---------------------------------------------------------------        
useage: drib list [-p project]

    sub commands 
        none
        
    options
        -p, --project       Show only list of packages for given project
        
    example
        drib list
        drib list test