///
///  mod_drib
/// ======================
///  (c) 2010 Travis Kuhl
///
///
///  to compile
///   apxs -c mod_drib.c 
///   apxs -i -a mod_drib.la 
///


// core stuff
#include "apr.h"
#include "apr_strings.h"

#include "ap_config.h"
#include "httpd.h"
#include "http_config.h"
#include "http_request.h"
#include "http_log.h"

// there's a struct
typedef struct {
    apr_table_t *vars;
} drib_dir_config_rec;


// define our module data
module AP_MODULE_DECLARE_DATA drib_module;

// when we create our config 
// we need to find any settings
static void *create_env_dir_config(apr_pool_t *p, char *dummy) {

	// cnfg record
    drib_dir_config_rec *conf = apr_palloc(p, sizeof(*conf));
	
	// make a table
    conf->vars = apr_table_make(p, 10);

	// file info
	apr_file_t *fp = NULL;
	char line[1024+1];	
	char *k;
	char *v;
	
	// try reading the file
	// if we can't just return OK
    if ( apr_file_open(&fp,"/usr/var/drib/settings.txt", APR_READ|APR_BUFFERED, APR_OS_DEFAULT,p) != APR_SUCCESS ) {
		return 0;
    }

	// get our lines
    while (apr_file_gets(line, sizeof(line), fp) == APR_SUCCESS) {
    	
    	// get the key and value from the line
    	k = strtok(line,"|");
    	v = strtok(strtok(NULL,"|"),"\n");

		// set in the env
		apr_table_set(conf->vars,k,v);

    }        
    
    return conf;

}

// hook up our env with our variables
static int drib_hook_fixups (request_rec *r) {

	// process env
    apr_table_t *e = r->subprocess_env;
    
    // get our conf
    drib_dir_config_rec *sconf = ap_get_module_config(r->per_dir_config, &drib_module);
    
    // cars
    apr_table_t *vars = sconf->vars;

	// nothing to set
    if (!apr_table_elts(sconf->vars)->nelts) {
        return DECLINED;
	}

	// merge our proess env
    r->subprocess_env = apr_table_overlay(r->pool, e, vars);

	// we're good
    return OK;

}


// register our hooks
static void mod_drib_register_hooks (apr_pool_t *p) {
   
    // fix me up
    ap_hook_fixups(drib_hook_fixups, NULL, NULL, APR_HOOK_LAST);    
    
}

// this is my module data
module AP_MODULE_DECLARE_DATA drib_module = {
	STANDARD20_MODULE_STUFF,
	create_env_dir_config,
	NULL,
	NULL,
	NULL,
	NULL,
	mod_drib_register_hooks,			/* callback for registering hooks */
};
