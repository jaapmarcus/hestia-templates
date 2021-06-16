#=======================================================================#
# Default Web Domain Template                                           #
# DO NOT MODIFY THIS FILE! CHANGES WILL BE LOST WHEN REBUILDING DOMAINS #
#=======================================================================#

server {
    listen      %ip%:%web_port%;
    server_name %domain_idn% %alias_idn%;

    root        %docroot%/pub;
    index       index.php;
    autoindex   off;
    charset     UTF-8;
    error_page  404 403 = /errors/404.php;
    add_header  "X-UA-Compatible" "IE=Edge";

    access_log  /var/log/nginx/domains/%domain%.log combined;
    access_log  /var/log/nginx/domains/%domain%.bytes bytes;
    error_log   /var/log/nginx/domains/%domain%.error.log error;
        
    include %home%/%user%/conf/web/%domain%/nginx.forcessl.conf*;

    # PHP entry point for setup application
    location ~* ^/setup($|/) {
        root %docroot%;

        location ~ ^/setup/index.php {
            fastcgi_pass   %backend_lsnr%;
            fastcgi_index  index.php;
            fastcgi_param  SCRIPT_FILENAME  $document_root$fastcgi_script_name;
            include     %home%/%user%/conf/web/%domain%/nginx.fastcgi_cache.conf*;
            include        /etc/nginx/fastcgi_params;
        }

        location ~ ^/setup/(?!pub/). {
            deny all;
        }

        location ~ ^/setup/pub/ {
            add_header X-Frame-Options "SAMEORIGIN";
        }
    }
    
    location /sitemap.xml {
       root  /home/%user%/web/%domain%/public_html;
       try_files $uri sitemap.xml;
    }
    
    # PHP entry point for update application
    location ~* ^/update($|/) {
        root %docroot%;

        location ~ ^/update/index.php {
            fastcgi_split_path_info ^(/update/index.php)(/.+)$;
            fastcgi_pass   %backend_lsnr%;
            fastcgi_index  index.php;
            fastcgi_param  SCRIPT_FILENAME  $document_root$fastcgi_script_name;
            fastcgi_param  PATH_INFO        $fastcgi_path_info;
            include     %home%/%user%/conf/web/%domain%/nginx.fastcgi_cache.conf*;
            include        /etc/nginx/fastcgi_params;
        }

        # Deny everything but index.php
        location ~ ^/update/(?!pub/). {
            deny all;
        }

        location ~ ^/update/pub/ {
            add_header X-Frame-Options "SAMEORIGIN";
        }
    }

    location / {
        try_files $uri $uri/ /index.php?$args;
    }

    location /pub/ {
        location ~ ^/pub/media/(downloadable|customer|import|theme_customization/.*\.xml) {
            deny all;
        }

        alias %docroot%/pub/;
        add_header X-Frame-Options "SAMEORIGIN";
    }

    location /static/ {
        # Uncomment the following line in production mode
    
        # Remove signature of the static files that is used to overcome the browser cache
        
        location ~ ^/static/version {
            rewrite ^/static/(version\d*/)?(.*)$ /static/$2 last;
        }
    
        location ~* \.(ico|jpg|jpeg|png|gif|svg|swf|eot|ttf|otf|woff|woff2)$ {
            add_header Cache-Control "max-age=2592000, public";
            expires +1m;
            add_header X-Frame-Options "SAMEORIGIN";
    
    
            if (!-f $request_filename) {
                rewrite ^/static/(version\d*/)?(.*)$ /static.php?resource=$2 last;
            }
        }
        location ~* \.(js|css)$ {
            add_header Cache-Control "max-age=86400, public";
            expires +1d;
            add_header X-Frame-Options "SAMEORIGIN";
    
    
            if (!-f $request_filename) {
                rewrite ^/static/(version\d*/)?(.*)$ /static.php?resource=$2 last;
            }  
        }
    
        location ~* \.(zip|gz|gzip|bz2|csv|xml)$ {
            add_header Cache-Control "max-age=2592000, public";
            expires +1m;
            add_header X-Frame-Options "SAMEORIGIN";
    
            if (!-f $request_filename) {
                rewrite ^/static/(version\d*/)?(.*)$ /static.php?resource=$2 last;
            }
        }
    
        if (!-f $request_filename) {
            rewrite ^/static/(version\d*/)?(.*)$ /static.php?resource=$2 last;
        }
    
        add_header X-Frame-Options "SAMEORIGIN";
    }

    location /media/ {
        try_files $uri $uri/ /get.php?$args;
    
        location ~ ^/media/theme_customization/.*\.xml {
            deny all;
        }
    
        location ~* \.(ico|jpg|jpeg|png|gif|svg|swf|eot|ttf|otf|woff|woff2)$ {
            add_header Cache-Control "max-age=2592000, public";
            expires +1m;
            add_header X-Frame-Options "SAMEORIGIN";
            try_files $uri $uri/ /get.php?$args;
        }
        location ~* \.(js|css)${
            add_header Cache-Control "max-age=86400, public";
            expires +1d;
            add_header X-Frame-Options "SAMEORIGIN";
            try_files $uri $uri/ /get.php?$args;
        }
        location ~* \.(zip|gz|gzip|bz2|csv|xml)$ {
            add_header Cache-Control "max-age=2592000, public";
            expires +1m;
            add_header X-Frame-Options "SAMEORIGIN";
            try_files $uri $uri/ /get.php?$args;
        }
    
        add_header X-Frame-Options "SAMEORIGIN";
    }

    location /media/customer/ {
        deny all;
    }

    location /media/downloadable/ {
        deny all;
    }

    location /media/import/ {
        deny all;
    }

    # PHP entry point for main application
    location ~ (index|get|static|report|404|503)\.php$ {
        try_files $uri =404;

        fastcgi_pass   %backend_lsnr%;
        fastcgi_buffers 1024 4k;
        fastcgi_read_timeout 600s;
        fastcgi_connect_timeout 600s;

        fastcgi_index  index.php;
        fastcgi_param  SCRIPT_FILENAME  $document_root$fastcgi_script_name;
        include     %home%/%user%/conf/web/%domain%/nginx.fastcgi_cache.conf*;
        include        /etc/nginx/fastcgi_params;
    }


    # Banned locations (only reached if the earlier PHP entry point regexes don't match)
    location ~ /\.(?!well-known\/) { 
       deny all; 
       return 404;
    }

    location /vstats/ {
        alias   %home%/%user%/web/%domain%/stats/;
        include %home%/%user%/web/%domain%/stats/auth.conf*;
    }

    include     /etc/nginx/conf.d/phpmyadmin.inc*;
    include     /etc/nginx/conf.d/phppgadmin.inc*;
    include     %home%/%user%/conf/web/%domain%/nginx.conf_*;
}
