import os

COOKIES_WHITELIST = os.environ.get('COOKIES_WHITELIST', '(NO_CACHE)').strip()

cookie_conf = """
sub vcl_recv {

  # Remove all cookies and then list the ones that are required to NOT
  # cache the page. If, after running this code we find that any cookies 
  # remain, we will pass as the page cannot be cached.
  if (req.http.Cookie) {
    # 1. Append a semi-colon to the front of the cookie string.
    # 2. Remove all spaces that appear after semi-colons.
    # 3. Match the cookies we want to keep, adding the space we removed
    #    previously back. (\\1) is first matching group in the regsuball.
    # 4. Remove all other cookies, identifying them by the fact that they have
    #    no space after the preceding semi-colon.
    # 5. Remove all spaces and semi-colons from the beginning and end of the
    #    cookie string.
    set req.http.Cookie = ";" + req.http.Cookie;
    set req.http.Cookie = regsuball(req.http.Cookie, "; +", ";");
    set req.http.Cookie = regsuball(req.http.Cookie, ";%(white_cookies)=", "; \\1=");
    set req.http.Cookie = regsuball(req.http.Cookie, ";[^ ][^;]*", "");
    set req.http.Cookie = regsuball(req.http.Cookie, "^[; ]+|[; ]+$", "");

    if (req.http.Cookie == "") {
      # If there are no remaining cookies, remove the cookie header. If there
      # aren't any cookie headers, Varnish's default behavior will be to cache
      # the page.
      unset req.http.Cookie;
    }
    else {
      # If there are any cookies left, do not
      # cache the page and pass it through.
      return (pass);
    }
  }
}
"""

cookie_conf_add = cookie_conf.replace(r'%(white_cookies)', COOKIES_WHITELIST)
with open("/etc/varnish/conf.d/cookie_config.vcl", "w") as cookie_file:
    cookie_file.write(cookie_conf_add)
