<?Lassoscript
// Downloaded from TagSwap 10/3/07
// Author	Johan Sölve
// Usage	setHTTPstatus: '404 Not Found'
define_tag: 'setHTTPstatus', -required='statuscode';
    $__http_header__ = (string_replaceregexp: $__http_header__,
        -find='(^HTTP\\S+)\\s+.*?\n\n',
        -replace='\\1 ' + #statuscode + '\n\n');
/define_tag;
?>