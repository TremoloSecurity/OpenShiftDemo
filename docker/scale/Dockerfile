FROM centos:7
MAINTAINER Tremolo Security, Inc. - Docker <docker@tremolosecurity.com>
USER root

ENV CATALINA_HOME /usr/local/tomcat
ENV PATH $CATALINA_HOME/bin:$PATH

ENV SCALE_MAIN_SOURCE_URL https://www.tremolosecurity.com/nexus/service/local/repositories/releases/content/tremolosecurity-scale-tomcat/scale-application/1.0.6
ENV SCALE_MAIN_WAR scale-application-1.0.6.war
ENV SCALE_APP_PATH scale


RUN yum -y install wget which java-1.8.0-openjdk-devel unzip; \
  mkdir -p "$CATALINA_HOME" ; \
  mkdir -p /etc/scale ; \
  mkdir -p /var/lib/unison-activemq ; \
  mkdir -p /usr/local/tomcat/bin ; \
  mkdir -p /tmp/scripts ; \
  groupadd -r openunison -g 433 && \
  useradd -u 431 -r -g openunison -d /usr/local/tomcat -s /sbin/nologin -c "Docker image user" openunison && \
  chown -R openunison:openunison /etc/scale && \
  chown -R openunison:openunison "$CATALINA_HOME"


WORKDIR $CATALINA_HOME
USER openunison

# see https://www.apache.org/dist/tomcat/tomcat-8/KEYS
RUN gpg --keyserver pool.sks-keyservers.net --recv-keys \
	05AB33110949707C93A279E3D3EFE6B686867BA6 \
	07E48665A34DCAFAE522E5E6266191C37C037D42 \
	47309207D818FFD8DCD3F83F1931D684307A10A5 \
	541FBE7D8F78B25E055DDEE13C370389288584E7 \
	61B832AC2F1C5A90F0F9B00A1C506407564C17A3 \
	79F7026C690BAA50B92CD8B66A3AD3F4F22C4FED \
	9BA44C2621385CB966EBA586F72C284D731FABEE \
	A27677289986DB50844682F8ACB77FC2E86E29AC \
	A9C5DF4D22E99998D9875A5110C01C5A2F6059E7 \
	DCFD35E0BF8CA7344752DE8B6FB21E8933C60243 \
	F3A04C595DB5B6A5F1ECA43E3B7BBB100D811BBE \
	F7DA48BB64BCB84ECBA7EE6935CD23C10D498E23

ENV TOMCAT_MAJOR 8
ENV TOMCAT_VERSION 8.0.32
ENV TOMCAT_TGZ_URL https://www.apache.org/dist/tomcat/tomcat-$TOMCAT_MAJOR/v$TOMCAT_VERSION/bin/apache-tomcat-$TOMCAT_VERSION.tar.gz

ENV OPEN_UNISON_VERSION 1.0.6
ENV OPEN_UNISON_WAR_URL https://www.tremolosecurity.com/nexus/service/local/repositories/releases/content/com/tremolosecurity/unison/open-unison-webapp/$OPEN_UNISON_VERSION/open-unison-webapp-$OPEN_UNISON_VERSION.war
ENV CATALINA_OPTS -XX:+UseParallelGC  -Djava.security.egd=file:/dev/./urandom

ADD ./scripts/*.sh /tmp/scripts/

ADD ./conf/scale-application-context.xml /tmp/context.xml

RUN set -x \
	&& curl -fSL "$TOMCAT_TGZ_URL" -o tomcat.tar.gz \
	&& curl -fSL "$TOMCAT_TGZ_URL.asc" -o tomcat.tar.gz.asc \
	&& gpg --verify tomcat.tar.gz.asc \
	&& tar -xvf tomcat.tar.gz --strip-components=1 \
	&& rm bin/*.bat \
	&& rm tomcat.tar.gz* ; \
  chown -R openunison:openunison /usr/local/tomcat ; \
  rm -rf /usr/local/tomcat/webapps/* ; \
  wget https://www.tremolosecurity.com/nexus/service/local/repositories/releases/content/tremolosecurity-unison/unison-lastmile-tomcat6/1.0.6/unison-lastmile-tomcat6-1.0.6.zip -O /tmp/lm.zip ; \
  unzip /tmp/lm.zip -d /tmp/ ; \
  mv /tmp/unison-lastmile-tomcat-6-1.0.6/*.jar /usr/local/tomcat/lib/ ; \
  rm -rf /tmp/unison-lastmile-tomcat6-1.0.6* ; \
  rm -rf /tmp/lm.zip ; \
  cp /tmp/scripts/* /usr/local/tomcat/bin/ ; \
  /usr/local/tomcat/bin/scaleMainApp.sh ; \
  rm /usr/local/tomcat/webapps/$SCALE_APP_PATH/WEB-INF/log4j.xml ; \
  cp /tmp/context.xml /usr/local/tomcat/webapps/$SCALE_APP_PATH/META-INF/ ; \
  chmod -R o+rw /usr/local/tomcat

CMD ["catalina.sh", "run"]
