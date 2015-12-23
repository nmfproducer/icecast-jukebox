package WAF;
use strict;
use warnings;

use Exporter::Lite;
our @EXPORT = qw(get post any waf);

use Router::Simple;
our $router = Router::Simple->new();

use Data::Section::Simple;
our $data_section = Data::Section::Simple->new(caller(0));

sub get {
    my ($url, $action) = @_;
    any($url, $action, ['GET']);
}

sub post {
    my ($url, $action) = @_;
    any($url, $action, ['POST']);
}

sub any {
    my ($url, $action, $methods) = @_;
    my $opts = {};
    $opts->{method} = $methods if $methods;
    $router->connect($url, { action => $action }, $opts);
}

sub waf {
    return my $app = sub {
        my $env = shift;

        my $context = WAF::Context->new(
            env          => $env,
            data_section => $data_section,
        );

        if (my $p = $router->match($env)) {
            $p->{action}->($context);
            return $context->res->finalize;
        }
        else {
            [404, [], ['not found']];
        }
    };
}



package WAF::Context;

use Data::Section::Simple qw(get_data_section);

sub new {
    my ($class, %args) = @_;
    return bless {
        env          => $args{env},
        data_section => $args{data_section},
    }, $class;
}

sub env {
    my $self = shift;
    return $self->{env};
}

sub data_section {
    my $self = shift;
    return $self->{data_section};
}

sub req {
    my $self = shift;
    return $self->{_req} ||= WAF::Request->new($self->env);
}

sub res {
    my $self = shift;
    return $self->{_res} ||= $self->req->new_response(200);
}

sub render {
    my ($self, $tmpl_name, $args) = @_;
    my $str  = $self->data_section->get_data_section($tmpl_name);
    my $body = WAF::View->render_string($str, $args);
    return $self->res->body($body);
}

use MP3::Info;
use Data::Dumper;

sub indexpage{
    my $self = shift;
    my $output = "";
    my @data = ();

    my $host = $self->req->{env}->{HTTP_HOST};
    $host =~ s/:\d+//;

    foreach my $mountpoint (qw/music imas radio/){
        my $filename = (split /\n/,`cat /run/ices-$mountpoint.file`)[0];
        my $utime = (stat "/run/ices-$mountpoint.file")[9];
        my $hinfo = get_mp3info($filename);
        my $info = "ERROR";
        my $songtime = 0;
        if(defined($hinfo)){
            my $secs = $hinfo->{SECS};
            my $bitrate = $hinfo->{BITRATE};
            $bitrate = "(VBR)$bitrate" if($hinfo->{VBR} == 1);
            
            my $fs = $hinfo->{FREQUENCY};
            my $stereo = $hinfo->{STEREO};
            my $time = $hinfo->{TIME};
            $time =~ s/:/分/;
            $time =~ s/$/秒/;
            $info = "${time}, ${bitrate}kbps, ${fs}kHz";
            $songtime = int $secs;
        }
        my ($sec,$min,$hour,$mday,$month,$year,$wday,$stime)
            = localtime $utime;
        my $starttime = sprintf "%02d:%02d:%02d", $hour, $min, $sec;
        ($sec,$min,$hour,$mday,$month,$year,$wday,$stime)
            = localtime ($utime + $songtime);
        my $endtime = sprintf "%02d:%02d:%02d", $hour, $min, $sec;
        push @data, {
            mountpoint => $mountpoint,
            filename => $filename,
            starttime => $starttime,
            starttimeunix => $utime,
            endtime => $endtime,
            endtimeunix => $utime + $songtime,
            info => $info,
            host => $host,
            port => "8080",
            # etc => Dumper($info),
        };
    }

    $output = $self->render('index.tt', { data => \@data, servertime => time(), });

    return $self->res->body($output);
}

sub skip{
    my $self = shift;
    my $path = $self->req->path();
    if($path =~ m@^/skip/([^/]*)$@){    
        `cat /run/ices-$1.pid | xargs kill -USR1`;
        sleep 1;
        return $self->res->body("success: $1") if $? == 0;
    }
    return $self->not_found();
}

sub request{
    my $self = shift;
    my $path = $self->req->path();
    if($path =~ m@^/request/([^/]*)/(.+)$@){
        my $tmp = "/run/ices-$1";
        open REQ, "<${tmp}.req";
        my @reqest = grep {/.+/} map {chomp;$_} <REQ>;
        close REQ;

        push @reqest, $2;
        open REQ, ">${tmp}.req";
        print REQ join "\n", @reqest;
        print REQ "\n";
        close REQ;

        return $self->res->body("success: $1") if $? == 0;
    }
    return $self->not_found();
}

sub static{
    my $self = shift;
    my $path = "." . $self->req->path();

    $path =~ s@/\.\./@/@g;
    if(-f $path){
        return $self->res->body(`cat $path`);
    }
    else{
        return $self->res->body($path);
        return $self->not_found();
    }
}

sub not_found{
    my $self = shift;
    $self->{_res} = $self->req->new_response(404);
    return $self->res->body("sorry... 404 not found");
}

package WAF::Request;

use parent qw(Plack::Request);

package WAF::Response;

use parent qw(Plack::Response);




package WAF::View;

use Text::Xslate;

our $tx = Text::Xslate->new(
#    syntax => 'TTerse',
#    module => [ qw(Text::Xslate::Bridge::TT2Like) ],
);

sub render_string {
    my ($class, $str, $args) = @_;
    return $tx->render_string($str, $args);
}

1;
