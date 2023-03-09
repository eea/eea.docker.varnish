vcl 4.1;

import std;
import directors;
import dynamic;

backend default none;

sub vcl_init {

  new cluster = dynamic.director(port = "<VARNISH_BACKEND_PORT>", ttl = <VARNISH_DNS_TTL>);

}

acl purge {
    "localhost";
    "127.0.0.1";
    "172.17.0.0/16"; # Docker network
    "10.42.0.0/16";  # Rancher network
    "10.62.0.0/16";  # Rancher network
    "10.120.10.0/24"; # Internal networks
    "10.120.20.0/24"; # Internal networks
    "10.120.30.0/24"; # Internal networks
}



sub vcl_recv {

    set req.backend_hint = cluster.backend("<VARNISH_BACKEND>");
    set req.http.X-Varnish-Routed = "1";


    if (req.http.X-Forwarded-Proto == "https" ) {
        set req.http.X-Forwarded-Port = "443";
    } else {
        set req.http.X-Forwarded-Port = "80";
        set req.http.X-Forwarded-Proto = "http";
    }

    set req.http.X-Username = "Anonymous";

    # PURGE - The CacheFu product can invalidate updated URLs 
    if (req.method == "PURGE") {
            if (!client.ip ~ purge) {
                return (synth(405, "Not allowed."));
            }

            # replace normal purge with ban-lurker way - may not work
            # Cleanup double slashes: '//' -> '/' - refs #95891
            ban ("obj.http.x-url == " + regsub(req.url, "\/\/", "/"));
            return (synth(200, "Ban added. URL will be purged by lurker"));
    }

    if (req.method == "BAN") {
        # Same ACL check as above:
        if (!client.ip ~ purge) {
            return(synth(403, "Not allowed."));
        }
        ban("req.http.host == " + req.http.host +
            " && req.url == " + req.url);
            # Throw a synthetic page so the
            # request won't go to the backend.
            return(synth(200, "Ban added")
        );
    }

    # Only deal with "normal" types
    if (req.method != "GET" &&
           req.method != "HEAD" &&
           req.method != "PUT" &&
           req.method != "POST" &&
           req.method != "TRACE" &&
           req.method != "OPTIONS" &&
           req.method != "DELETE") {
        /* Non-RFC2616 or CONNECT which is weird. */
        return(pipe);
    }


    # Only cache GET or HEAD requests. This makes sure the POST requests are always passed.
    if (req.method != "GET" && req.method != "HEAD") {
        return(pass);
    }


    if (req.http.Expect) {
        return(pipe);
    }

    if (req.http.If-None-Match && !req.http.If-Modified-Since) {
        return(pass);
    }


    # Do not cache RestAPI authenticated requests
    if (req.http.Authorization || req.http.Authenticate) {
        set req.http.X-Username = "Authenticated (RestAPI)";

        # pass (no caching)
        unset req.http.If-Modified-Since;
        return(pass);
    }

    set req.http.UrlNoQs = regsub(req.url, "\?.*$", "");
    # Do not cache authenticated requests
    if (req.http.Cookie && req.http.Cookie ~ "__ac(|_(name|password|persistent))=")
    {
       if (req.http.UrlNoQs ~ "\.(js|css)$") {
            unset req.http.cookie;
            return(pipe);
        }

        set req.http.X-Username = regsub( req.http.Cookie, "^.*?__ac=([^;]*);*.*$", "\1" );

        # pass (no caching)
        unset req.http.If-Modified-Since;
        return(pass);
    }

    # Do not cache login form
    if (req.url ~ "login_form$" || req.url ~ "login$")
    {
        # pass (no caching)
        unset req.http.If-Modified-Since;
        return(pass);
    }



    ### always cache these items:

    # javascript and css
    if (req.method == "GET" && req.url ~ "\.(js|css)") {
        return(hash);
    }

    ## images
    if (req.method == "GET" && req.url ~ "\.(gif|jpg|jpeg|bmp|png|tiff|tif|ico|img|tga|wmf)$") {
        return(hash);
    }

    ## multimedia ?
    # if (req.method == "GET" && req.url ~ "\.(svg|swf|ico|mp3|mp4|m4a|ogg|mov|avi|wmv)$") {
    #    return(hash);
    # }

    ## xml
    if (req.method == "GET" && req.url ~ "\.(xml)$") {
        return(hash);
    }

    ## scale
    if (req.method == "GET" && req.url ~ "(icon|tile|thumb|mini|preview|teaser|large|larger|great|huge|small|medium|big|tiny)$") {
        return(hash);
    }

    ## for some urls or request we can do a pass here (no caching) ?
    if (req.method == "GET" && (req.url ~ "aq_parent" || req.url ~ "manage$" || req.url ~ "manage_workspace$" || req.url ~ "manage_main$" || req.url ~ "@@rdf")) {
        return(pass);
    }


    /* Cookie whitelist, remove all not in there */
    if (req.http.Cookie) {
        set req.http.Cookie = ";" + req.http.Cookie;
        set req.http.Cookie = regsuball(req.http.Cookie, "; +", ";");
        set req.http.Cookie = regsuball(req.http.Cookie, ";(statusmessages|cart|__ac|_ZopeId|__cp)=", "; \1=");
        set req.http.Cookie = regsuball(req.http.Cookie, ";[^ ][^;]*", "");
        set req.http.Cookie = regsuball(req.http.Cookie, "^[; ]+|[; ]+$", "");
        if (req.http.Cookie == "") {
            unset req.http.Cookie;
        }
    }


    # Large static files should be piped, so they are delivered directly to the end-user without
    # waiting for Varnish to fully read the file first.

    if (req.url ~ "^[^?]*\.(mp[34]|rar|rpm|tar|tgz|gz|wav|zip|bz2|xz|7z|avi|mov|ogm|mpe?g|mk[av]|webm)(\?.*)?$") {
        unset req.http.Cookie;
        return(pipe);
    }



    ## lookup anything else
    return(hash);
}

sub vcl_pipe {
    # This is not necessary if we do not do any request rewriting
    set req.http.connection = "close";
    return(pipe);
}


sub vcl_pass {
    return (fetch);
}

sub vcl_purge {
    return (synth(200, "Purged"));
}

sub vcl_hit {
    if (obj.ttl >= 0s) {
        // A pure unadultered hit, deliver it
        # normal hit
        return (deliver);
    }

    # We have no fresh fish. Lets look at the stale ones.
    if (std.healthy(req.backend_hint)) {
        # Backend is healthy. Limit age to 10s.
        if (obj.ttl + 10s > 0s) {
            set req.http.grace = "normal(limited)";
            return (deliver);
        } else {
            # No candidate for grace. Fetch a fresh object.
            return(pass);
        }
    } else {
        # backend is sick - use full grace
        // Object is in grace, deliver it
        // Automatically triggers a background fetch
        if (obj.ttl + obj.grace > 0s) {
            set req.http.grace = "full";
            return (deliver);
        } else {
            # no graced object.
            return (pass);
        }
    }

    if (req.method == "PURGE") {
        set req.method = "GET";
        set req.http.X-purger = "Purged";
        return(synth(200, "Purged. in hit " + req.url));
    }

    // fetch & deliver once we get the result
    return (pass); # Dead code, keep as a safeguard
}

sub vcl_miss {

    if (req.method == "PURGE") {
        set req.method = "GET";
        set req.http.X-purger = "Purged-possibly";
        return(synth(200, "Purged. in miss " + req.url));
    }

    // fetch & deliver once we get the result
    return (fetch);
}

sub vcl_backend_fetch{
    return (fetch);
}

sub vcl_backend_response {
    # needed for ban-lurker
    # Cleanup double slashes: '//' -> '/' - refs #95891
    set beresp.http.x-url = regsub(bereq.url, "\/\/", "/");
    set beresp.http.X-Backend-Name = beresp.backend.name;

    # stream possibly large files
    if (bereq.url ~ "^[^?]*\.(mp[34]|rar|rpm|tar|tgz|gz|wav|zip|bz2|xz|7z|avi|mov|ogm|mpe?g|mk[av]|webm)(\?.*)?$") {
        unset beresp.http.set-cookie;
        set beresp.http.X-Cache-Stream = "YES";
        set beresp.http.X-Cacheable = "NO - File Stream";
        set beresp.uncacheable = true;
        set beresp.do_stream = true;
        return(deliver);
    }

    # cache all XML and RDF objects for 1 day
    if (beresp.http.Content-Type ~ "(text\/xml|application\/xml|application\/atom\+xml|application\/rss\+xml|application\/rdf\+xml)") {
        set beresp.ttl = 1d;
        set beresp.http.X-Varnish-Caching-Rule-Id = "xml-rdf-files";
        set beresp.http.X-Varnish-Header-Set-Id = "cache-in-proxy-24-hours";
    }

    # Headers for webfonts and truetype fonts
    if (beresp.http.Content-Type ~ "(application\/vnd.ms-fontobject|font\/truetype|application\/font-woff|application\/x-font-woff)") {
        # fix for loading Font Awesome under IE11 on Win7, see #94853
        if (bereq.http.User-Agent ~ "Trident" || bereq.http.User-Agent ~ "Windows NT 6.1") {
            unset beresp.http.Vary;
        }
    }


    # The object is not cacheable
    if (beresp.http.Set-Cookie) {
        set beresp.http.X-Cacheable = "NO - Set Cookie";
        set beresp.ttl = 0s;
        set beresp.uncacheable = true;
    } elsif (beresp.http.Cache-Control ~ "private") {
        set beresp.http.X-Cacheable = "NO - Cache-Control=private";
        set beresp.uncacheable = true;
        set beresp.ttl = <VARNISH_BERESP_TTL>;
    } elsif (beresp.http.Surrogate-control ~ "no-store") {
        set beresp.http.X-Cacheable = "NO - Surrogate-control=no-store";
        set beresp.uncacheable = true;
        set beresp.ttl = <VARNISH_BERESP_TTL>;
    } elsif (!beresp.http.Surrogate-Control && beresp.http.Cache-Control ~ "no-cache|no-store") {
        set beresp.http.X-Cacheable = "NO - Cache-Control=no-cache|no-store";
        set beresp.uncacheable = true;
        set beresp.ttl = <VARNISH_BERESP_TTL>;
    } elsif (beresp.http.Vary == "*") {
        set beresp.http.X-Cacheable = "NO - Vary=*";
        set beresp.uncacheable = true;
        set beresp.ttl = <VARNISH_BERESP_TTL>;

    # ttl handling
    } elsif (beresp.ttl < 0s) {
        set beresp.http.X-Cacheable = "NO - TTL < 0";
        set beresp.uncacheable = true;
    } elsif (beresp.ttl == 0s) {
        set beresp.http.X-Cacheable = "NO - TTL = 0";
        set beresp.uncacheable = true;

    # Varnish determined the object was cacheable
    } else {
        set beresp.http.X-Cacheable = "YES";
    }

    # Do not cache 5xx errors
    if (beresp.status >= 500 && beresp.status < 600) {
        unset beresp.http.Cache-Control;
        set beresp.http.X-Cache = "NOCACHE";
        set beresp.http.Cache-Control = "no-cache, max-age=0, must-revalidate";
        set beresp.ttl = 0s;
        set beresp.http.Pragma = "no-cache";
        set beresp.uncacheable = true;
        return(deliver);
    }

    # TODO this one is very plone specific and should be removed, not sure if its needed any more
    if (bereq.url ~ "(createObject|@@captcha)") {
        set beresp.uncacheable = true;
        return(deliver);
    }

    set beresp.ttl = <VARNISH_BERESP_GRACE>;
    set beresp.ttl = <VARNISH_BERESP_KEEP>;
    return (deliver);

}



sub vcl_deliver {
    set resp.http.grace = req.http.grace;

    # add a note in the header regarding the backend
    set resp.http.X-Backend = req.backend_hint;

    if (obj.hits > 0) {
         set resp.http.X-Cache = "HIT";
    } else {
        set resp.http.X-Cache = "MISS";
    }
    /* Rewrite s-maxage to exclude from intermediary proxies
      (to cache *everywhere*, just use 'max-age' token in the response to avoid
      this override) */
    if (resp.http.Cache-Control ~ "s-maxage") {
        set resp.http.Cache-Control = regsub(resp.http.Cache-Control, "s-maxage=[0-9]+", "s-maxage=0");
    }
    /* Remove proxy-revalidate for intermediary proxies */
    if (resp.http.Cache-Control ~ ", proxy-revalidate") {
        set resp.http.Cache-Control = regsub(resp.http.Cache-Control, ", proxy-revalidate", "");
    }
    # set audio, video and pdf for inline display
    if (resp.http.Content-Type ~ "audio/" || resp.http.Content-Type ~ "video/" || resp.http.Content-Type ~ "/pdf") {
        set resp.http.Content-Disposition = regsub(resp.http.Content-Disposition, "attachment;", "inline;");
    }

}


sub vcl_backend_error {
  if ( beresp.status >= 500 && beresp.status <= 505) {
    synthetic({"<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
            <html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en-US" lang="en-US">
            <head>
            <meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
            <style type="text/css">
            html,
            body {
              height: 100%;
              width: 100%;
              padding: 0;
              margin: 0;
              border: 0;
              overflow: auto;
              background-color: #006699;
              color: #fff;
              font-family: Arial,sans-serif;
            }
            .vertical-align {
              display: block;
              width: 400px;
              position: relative;
              top: 50%;
              *top: 25%;
              -webkit-transform: translateY(-50%);
              -ms-transform: translateY(-50%);
              transform: translateY(-50%);
              margin: 0 auto;
            }
            button,
            a.button,
            a.button:link,
            a.button:visited {
              -webkit-appearance: none;
              -webkit-border-radius: 3px;
              -moz-border-radius: 3px;
              -ms-border-radius: 3px;
              -o-border-radius: 3px;
              border-radius: 3px;
              -webkit-background-clip: padding;
              -moz-background-clip: padding;
              background-clip: padding-box;
              background: #dddddd repeat-x;
              background-image: -webkit-gradient(linear, 50% 0%, 50% 100%, color-stop(0%, #ffffff), color-stop(100%, #dddddd));
              background-image: -webkit-linear-gradient(#ffffff, #dddddd);
              background-image: -moz-linear-gradient(#ffffff, #dddddd);
              background-image: -o-linear-gradient(#ffffff, #dddddd);
              background-image: linear-gradient(#ffffff, #dddddd);
              border: 1px solid;
              border-color: #bbbbbb;
              cursor: pointer;
              color: #333333;
              display: inline-block;
              font: 15px/20px Arial, sans-serif;
              overflow: visible;
              margin: 0;
              padding: 3px 10px;
              text-decoration: none;
              vertical-align: top;
              width: auto;
              *padding-top: 2px;
              *padding-bottom: 0;
            }
            .btn-eea {
              background: #478ea5 repeat-x;
              background-image: -webkit-gradient(linear, 50% 0%, 50% 100%, color-stop(0%, #478ea5), color-stop(100%, #346f83));
              background-image: -webkit-linear-gradient(#478ea5, #346f83);
              background-image: -moz-linear-gradient(#478ea5, #346f83);
              background-image: -o-linear-gradient(#478ea5, #346f83);
              background-image: linear-gradient(#478ea5, #346f83);
              border: 1px solid;
              border-color: #265a6c;
              color: white;
            }
            button:hover,
            a.button:hover {
              background-image:none;
            }
            hr {
              opacity: 0.5;
              margin: 12px 0;
              border: 0!important;
              height: 1px;
              background: white;
            }
            a,
            a:link,
            a:visited {
              color: white;
            }
            .huge {
              font-size: 72px;
            }
            .clearfix:before,
            .clearfix:after {
                display:table;
                content:" ";
            }
            .clearfix:after{
                clear:both;
            }
            .pull-left {
                float: left;
            }
            .pull-right {
                float: right;
            }
            </style>
            </head>
            <body>
            <div class="vertical-align">
              <div style="text-align: center;">
                <h2 style="margin: 12px 0;">Our apologies, the website has encountered an error.</h2>
                <hr>
                <p style="font-style: italic;">We have been notified by the error and will look at it as soon as possible. You may want to visit the <a href="https://status.eea.europa.eu">EEA Systems Status</a> site to see latest status updates from EEA Systems.</p>
                <p style="font-size: 90%"><a href="http://www.eea.europa.eu/">European Environment Agency</a>, Kongens Nytorv 6, 1050 Copenhagen K, Denmark - Phone: +45 3336 7100</p>  <br>
                </p>
              </div>
            </div>
            <script type="text/javascript">
              document.getElementById("focus").focus();
            </script>
            </body></html>
    "});

  }

  return (deliver);
}

sub vcl_synth {
    if (resp.status == 503 && resp.http.X-Backend ~ "auth" && req.method == "GET" && req.restarts < 2) {
      return (restart);
    }

    set resp.http.Content-Type = "text/html; charset=utf-8";

    if (req.http.X-Username ~ "Anonymous") {
        set req.http.X-Isanon = "Anonymous";
    }
    else {
        set req.http.X-Isanon = "Authenticated";
    }

    if ( resp.status >= 500 && resp.status <= 505) {
        # synthetic(std.fileread("/etc/varnish/500msg.html"));
        synthetic({"<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
            <html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en-US" lang="en-US">
            <head>
            <meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
            <style type="text/css">
            html,
            body {
              height: 100%;
              width: 100%;
              padding: 0;
              margin: 0;
              border: 0;
              overflow: auto;
              background-color: #006699;
              color: #fff;
              font-family: Arial,sans-serif;
            }
            .vertical-align {
              display: block;
              width: 400px;
              position: relative;
              top: 50%;
              *top: 25%;
              -webkit-transform: translateY(-50%);
              -ms-transform: translateY(-50%);
              transform: translateY(-50%);
              margin: 0 auto;
            }
            button,
            a.button,
            a.button:link,
            a.button:visited {
              -webkit-appearance: none;
              -webkit-border-radius: 3px;
              -moz-border-radius: 3px;
              -ms-border-radius: 3px;
              -o-border-radius: 3px;
              border-radius: 3px;
              -webkit-background-clip: padding;
              -moz-background-clip: padding;
              background-clip: padding-box;
              background: #dddddd repeat-x;
              background-image: -webkit-gradient(linear, 50% 0%, 50% 100%, color-stop(0%, #ffffff), color-stop(100%, #dddddd));
              background-image: -webkit-linear-gradient(#ffffff, #dddddd);
              background-image: -moz-linear-gradient(#ffffff, #dddddd);
              background-image: -o-linear-gradient(#ffffff, #dddddd);
              background-image: linear-gradient(#ffffff, #dddddd);
              border: 1px solid;
              border-color: #bbbbbb;
              cursor: pointer;
              color: #333333;
              display: inline-block;
              font: 15px/20px Arial, sans-serif;
              overflow: visible;
              margin: 0;
              padding: 3px 10px;
              text-decoration: none;
              vertical-align: top;
              width: auto;
              *padding-top: 2px;
              *padding-bottom: 0;
            }
            .btn-eea {
              background: #478ea5 repeat-x;
              background-image: -webkit-gradient(linear, 50% 0%, 50% 100%, color-stop(0%, #478ea5), color-stop(100%, #346f83));
              background-image: -webkit-linear-gradient(#478ea5, #346f83);
              background-image: -moz-linear-gradient(#478ea5, #346f83);
              background-image: -o-linear-gradient(#478ea5, #346f83);
              background-image: linear-gradient(#478ea5, #346f83);
              border: 1px solid;
              border-color: #265a6c;
              color: white;
            }
            button:hover,
            a.button:hover {
              background-image:none;
            }
            hr {
              opacity: 0.5;
              margin: 12px 0;
              border: 0!important;
              height: 1px;
              background: white;
            }
            a,
            a:link,
            a:visited {
              color: white;
            }
            .huge {
              font-size: 72px;
            }
            .clearfix:before,
            .clearfix:after {
                display:table;
                content:" ";
            }
            .clearfix:after{
                clear:both;
            }
            .pull-left {
                float: left;
            }
            .pull-right {
                float: right;
            }
            </style>
            </head>
            <body>
            <div class="vertical-align">
              <div style="text-align: center;">
                <h2 style="margin: 12px 0;">Our apologies, the website has encountered an error.</h2>
                <hr>
                <p style="font-style: italic;">We have been notified by the error and will look at it as soon as possible. You may want to visit the <a href="https://status.eea.europa.eu">EEA Systems Status</a> site to see latest status updates from EEA Systems.</p>
                <p style="font-size: 90%"><a href="http://www.eea.europa.eu/">European Environment Agency</a>, Kongens Nytorv 6, 1050 Copenhagen K, Denmark - Phone: +45 3336 7100</p>  <br>
                </p>
              </div>
            </div>
            <script type="text/javascript">
              document.getElementById("focus").focus();
            </script>
            </body></html>
    "});
    } else {
        synthetic({"<?xml version="1.0" encoding="utf-8"?>
        <!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN"
        "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
        <html>
        <head>
        <title>"} + resp.status + " " + resp.http.response + {"</title>
        </head>
        <body>
        <h1>Error "} + resp.status + " " + resp.http.response + {"</h1>
        <p>"} + resp.http.response + {"</p>
        <h3>Sorry, an error occured. If this problem persists Contact EEA Web Team (web.helpdesk at eea.europa.eu)</h3>
        <p>XID: "} + req.xid + {"</p>
        <address>
        <a href="http://www.varnish-cache.org/">Varnish</a>
        </address>
        </body>
        </html>
        "});
    }

    return (deliver);
}
