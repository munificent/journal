<%inherit file="base.mako" />
<!DOCTYPE html>
<html>
  <head>
    <meta http-equiv="Content-Type" content="text/html; charset=UTF-8"/>
    <%include file="head.mako" />
  </head>
  <body>
    <div class="overlay"></div>
    <%include file="header.mako" />
    ${next.body()}
    <%include file="footer.mako" />
  </body>
</html>
