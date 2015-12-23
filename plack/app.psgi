# app.psgi
use strict;
use warnings;

use WAF;

any '/' => sub {
    my $c = shift;
    $c->indexpage();
};

# get '/hoge' => sub {
#     my $c = shift;
#     $c->render('hoge.tt', { name => 'shiba_yu36' });
# };

# get '/index.css' => sub {
#     my $c = shift;
#     $c->render('index.css', { });
# };

get '/skip/*' => sub {
    my $c = shift;
    $c->skip();
};

get '/request/*' => sub {
    my $c = shift;
    $c->request();
};

get '/*' => sub {
    my $c = shift;
    $c->static();
};

waf;

__DATA__

@@ index.tt
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="ja-JP" lang="ja-JP">
  <head>
    <meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
    <title>Iccecast status page</title>
    <link rel="stylesheet" href="index.css" type="text/css" />
    <script type="text/javascript" src="index.js"></script>
    <meta name="viewport" content="width=device-width,
     initial-scale=1.0,user-scalable=yes" />
  </head>
  <body>
: for $data -> $item {
    <div class="item">
      <div class="mountpoint">
        <: $item.mountpoint :>
      </div>
      <div class="filename">
        <: $item.filename :>
      </div>
      <div class="info">
        <: $item.info :>
      </div>
      <div class="time">
        <span class="starttime">
        <: $item.starttime :>
        </span>
        --&gt;
        <span class="endtime">
        <: $item.endtime :>
        </span>
        <div class="timebar">
        </div>
        <div class="starttimeunix hidden">
          <: $item.starttimeunix :>
        </div>
        <div class="endtimeunix hidden">
          <: $item.endtimeunix :>
        </div>
      </div>
      <!--
      <div class="etc">
      <pre>
        <: $item.etc :>
        </pre>
      </div>
      -->
      <div class="link">
        play via: 
        <a href="http://<: $item.host :>:<: $item.port :>/<: $item.mountpoint :>.m3u">m3u</a>
        <a href="http://<: $item.host :>:<: $item.port :>/<: $item.mountpoint :>">browser</a>
        edit program:
        <a href="javascript:skip('<: $item.mountpoint :>');">skip</a>
        <a href="javascript:request('<: $item.mountpoint :>');">request</a>
      </div>
    </div>
: }
  <div id="servertime" class="servertime hidden">
    <: $servertime :>
  </div>
  <div id="emScale" class="hidden"></div>
  </body>
</html>

@@ hoge.tt
<html>
  <body>
    Hoge, [% name %]
  </body>
</html>

