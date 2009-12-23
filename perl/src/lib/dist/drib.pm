package drib::dist::drib;

# what we need
use HTTP::Request;
use Digest::MD5 qw(md5_hex);
use JSON;
use Data::Dumper;

# version
my $VERSION = "0.0.1";

# some constants
use constant API_HOST => "http://67.23.31.44";
use constant API_PORT => 4080;
use constant API_VERSION => "1";

sub new {

	# get 
	my($ref,$config) = @_;

	# get myself
	my $self = {};
	
	# add some properties
	$self->{key} = $config->get('key');
	$self->{secret} = $config->get('secret');
	$self->{host} = API_HOST;
	$self->{port} = API_PORT;
	$self->{version} = API_VERSION;
	
	# bless and return me
	bless($self); return $self;

}

sub check {

    # porjec
	my ($self,$project,$pkg,$ver) = @_;
	
	# make a package name
	my $name = $pkg."-".$ver;

	# get 
	my $resp = $self->_request({
	   'method' => 'GET',
	   'end' => "package/$project/$name"
    });
    
    # what 
    return ($resp?1:0);

}

sub get {

    # porjec
	my ($self,$project,$pkg,$ver) = @_;

	# make a package name
	my $name = $pkg."-".$ver;

	# get 
	my $resp = $self->_request({
	   'method' => 'GET',
	   'end' => "package/$project/$name/download",
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

    # lets send it to the server
    my $resp = $self->_request({
        'end'       => "package/$project/$pkg/$version?branch=$branch",
        'method'    => "PUT",
        'content'   => $tar
    });
 
    # resp
    return ($resp?1:0);
    
}

sub _request {

	my ($self,$args) = @_;
	
    # where should we end
	my $endpoint = $args->{end};
	my $method = $args->{method} || 'GET';
	my $accept = $args->{'accept'} || 'text/javascript';
	
    # module 
    my @parts = split(/\//,$endpoint);
    my $module = shift @parts;
    my $path = join('/',@parts);

	# url
	my $url = $self->{host} . ":" . $self->{port} . "/v" . $self->{version} . "/" . $endpoint;
	
    # sig
    my $sig = md5_hex($self->{secret}.$module.$method.$url);	

    # yes 
    my $req = HTTP::Request->new($method => $url);    
    
    # add some headers
    $req->header('x-drib-key'=>$self->{key});
    $req->header('x-drib-sig'=>$sig);
    
    # accept
    $req->header('accept'=>$args->{'accept'});
    
    # content 
    if ( $args->{content} ) {
        $req->content($args->{content});
    }

    # ua
    use LWP::UserAgent;
    
    # add a ua
    my $ua = LWP::UserAgent->new;
    
        # set ua
        $ua->agent("drib-perl/".$VERSION);

    # Pass request to the user agent and get a response back
    my $res = $ua->request($req);

    # Check the outcome of the response
    if ($res->is_success && $res->code == 200) {

        # javascript
        if ( $args->{'accept'} eq 'text/javascript' ) {
        
            # parse the json
            my $json = from_json($res->content);
    
            # reutrn
            return ($json?$json:0);
        
        }
        else {
            return $res->content;
        }
        
    }
    else {
        return 0;
    }    

}