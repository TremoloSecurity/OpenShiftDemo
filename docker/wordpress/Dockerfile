FROM wordpress

RUN apt-get update ; \
    apt-get install -y libboost-date-time1.55 wget ; \
    rm -rf /var/lib/apt/lists/* ; \
    wget https://www.tremolosecurity.com/dwn/tremolosecurity-downloads/lastmile/1.0.5/apache-2.4/unison-lastmile-1.x-httpd24-ubuntu14.tar.gz ; \
    tar -xvzf unison-lastmile-1.x-httpd24-ubuntu14.tar.gz ; \
    mv unison-lastmile-1.x-httpd24-ubuntu14/mod_auth_tremolo.so /usr/lib/apache2/modules/mod_auth_tremolo.so ; \
    rm -rf unison-lastmile-1.x-httpd24-ubuntu14*

ADD conf/auth_tremolo.load /etc/apache2/mods-enabled/auth_tremolo.load
ADD conf/wordpress.conf /etc/apache2/conf-enabled/wordpress.conf
