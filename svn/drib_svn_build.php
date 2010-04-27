#!/usr/bin/php
<?php

	// define 
	define("DB","/home/bolt/var/drib/svn_build_db.json");
	define("REPO","/home/drib/projects/");
	define("USER","drib");
	define("PWORD","8aPEWefr");

	// open the db
	$db = json_decode(file_get_contents(DB),true);

	// move to repo
	chdir(REPO);

	// update
	$cmd = "svn update . --username ".USER." --password ".PWORD.""; `$cmd`;

	// now find all pkg files 
	// and see what needs to be updated
	$pkgs = `find . -name "*.pkg"`;

	var_dump($pkgs); die;

?>