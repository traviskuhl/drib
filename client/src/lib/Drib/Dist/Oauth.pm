#
#  drib::dist::drib
# =================================
#  (c) Copyright Travis Kuhl 2009-10
#  
#
# This is free software. You may redistribute copies of it under the terms of
# the GNU General Public License <http://www.gnu.org/licenses/gpl.html>.
# There is NO WARRANTY, to the extent permitted by law.
#

package Drib::Dist::Oauth;

# what we need
use HTTP::Request;
use Digest::MD5 qw(md5_hex);
use JSON;
use Data::Dumper;
use Net::OAuth;
$Net::OAuth::PROTOCOL_VERSION = Net::OAuth::PROTOCOL_VERSION_1_0A;
use HTTP::Request::Common;
use Drib::Utils;
 use MIME::Base64;


sub new {

	# get 
	my($ref, $drib, $config) = @_;

	# get myself
	my $self = {};
	
	# add some properties
	$self->{drib} = $drib;
	$self->{key} = $config->{'key'};
	$self->{secret} = $config->{'secret'};
	$self->{get_url} = $config->{'get_url'};
	$self->{post_url} = $config->{'post_url'} || $self->{get_url};
	$self->{check_url} = $config->{'check_url'};
	$self->{error} = "";
	
	# bless and return me
	bless($self); return $self;

}

sub error {
	my $self = shift;
	return $self->{error};
}

sub check {

    # porjec
	my ($self,$project,$pkg,$ver) = @_;
	
	$path = $self->{check_url};
	
	# replace some vars
	$path =~ s/\%project/$project/ig;
	$path =~ s/\%name/$pkg/ig;
	$path =~ s/\%version/$ver/ig;		

	# get 
	my $resp = $self->_request({
	   'method' => 'HEAD',
	   'url' => $path
    });
    
    # what 
    return ($resp?$ver:0);

}

sub get {

    # porjec
	my ($self,$project,$pkg,$ver) = @_;

	$path = $self->{get_url};
	
	# replace some vars
	$path =~ s/\%project/$project/ig;
	$path =~ s/\%name/$pkg/ig;
	$path =~ s/\%version/$ver/ig;	

	# get 
	my $resp = $self->_request({
	   'method' => 'GET',
	   'url' => $path,
	   'accept' => 'application/gzip'
    });

    # return the file
    return $resp;
    
}

sub upload {

    # do it 
    my ($self,$args) = @_;

    # project
	my $project = $args->{project};
	my $user = $args->{username};
	my $pkg = $args->{name};
	my $version = $args->{version};
	my $branch = $args->{branch};
	my $tar = $args->{tar};

	# path
	$path = $self->{post_url};
	
	# replace some vars
	$path =~ s/\%project/$project/ig;
	$path =~ s/\%name/$pkg/ig;
	$path =~ s/\%version/$branch/ig;	

    # lets send it to the server
    my $resp = $self->_request({
        'url'       => $path,
        'method'    => "POST",
        'content'   => $tar
    });
 
    # resp
    return ($resp?1:0);
    
}

sub _request {

	my ($self,$args) = @_;
	
    # where should we end
	my $url = $args->{url};
	my $method = $args->{method} || 'GET';
	my $accept = $args->{'accept'} || 'text/javascript';
	
	
	my $request = Net::OAuth->request("consumer")->new(
	    protocol_version => Net::OAuth::PROTOCOL_VERSION_1_0A,	
		consumer_key => $self->{key},
		consumer_secret => $self->{secret},
		request_method => $method,
		signature_method => 'HMAC-SHA1',
		timestamp => time,
		nonce => rand_str(5),
		request_url => $url
	);	
	
	# sign
	$request->sign();		
   
    # ua
    use LWP::UserAgent;
    
    # add a ua
    my $ua = LWP::UserAgent->new;
    
        # set ua
        $ua->agent("drib-perl/".$VERSION);

    # Pass request to the user agent and get a response back
    my $res;

	# what
	my $req = HTTP::Request->new( $method => $request->to_url);
	$req->header("Authorize" => $request->to_authorization_header);
   	$req->header('accept'=>$accept);
        
    # content 
	if ( $args->{content} ) {
    	$req->content($args->{content});
    }		
	
	# resp
	$res = $ua->request($req);

    # Check the outcome of the response
    if ($res->is_success && $res->code == 200) {

		# head means good
		if ($method eq "HEAD") {
			return 1;
		}

        # javascript
        if ( $accept eq 'text/javascript' ) {
        
            # parse the json
            my $json = from_json($res->content);
    
            # reutrn
            return ($json?$json->{status}:0);
        
        }
        else {
            return $res->content;
        }
        
    }
    else { 
		# head means good
		if ($method eq "HEAD") {
			return 0;
		}        
    	my $r = from_json($res->content);
    	$self->{error} = $r->{error};
        return 0;
    }    

}

1;