# drib Developer Guide
This is a **guide** for **developers** to learn more about **drib**. If you have questions, feel free to ask them in the IRC #dribpdm.

## Overview
drib is a packaging and deployment program, that helps developers easy manage the process of packaging their code into 
easy executables and deploy their code. In most cases you can package and deploy your code in two commands. 

### Development Process
This is generally how we've used drib in our development process

 1. Create individual folders for each distinct part of a site: `frontend`, `api`, `config`, etc
 2. Within each part create `pkg`, `src`, `conf`, `test` folders
 3. Place package file and changelog in the `pkg` folder
 4. Place source code in src
 5. Place apache configurations in `conf`
 6. Place unit tests in `test`
 7. Symlink the packages during development, using `drib create --type=symlink` 
 8. Dist packages for deployment `drib create --dist`
 9. Install the packages from dist `drib install <package>`

## Packages
drib packages consist of two major parts, rolled into a single gzipped tarball. 

 1. **Your Code**
 2. **drib package file** The package file is a manifest that tells drib how to interact with #1. It also tells drib what to do when the code is installed

For more information about package files, check out the [package file docs](./packages.md)

## Creating & Installing Packages

## Using Dist

## drib Apache Module