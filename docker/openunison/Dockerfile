FROM centos:7
MAINTAINER Tremolo Security, Inc. - Docker <docker@tremolosecurity.com>
USER root

ENV CATALINA_HOME /usr/local/tomcat
ENV PATH $CATALINA_HOME/bin:$PATH



RUN yum -y install wget which java-1.8.0-openjdk-devel unzip; \
  mkdir -p "$CATALINA_HOME" ; \
  mkdir -p /etc/openunison ; \
  mkdir -p /var/lib/unison-activemq ; \
  groupadd -r openunison -g 433 && \
  useradd -u 431 -r -g openunison -d /usr/local/tomcat -s /sbin/nologin -c "Docker image user" openunison && \
  chown -R openunison:openunison /etc/openunison && \
  chown -R openunison:openunison "$CATALINA_HOME" ; \
  chown -R openunison:openunison /var/lib/unison-activemq


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
ENV OPENUNISON_WS_WEBXML https://raw.githubusercontent.com/TremoloSecurity/OpenUnison/1.0.6-Dev/unison/open-unison-webapp-webservices/src/main/webapp/WEB-INF/web.xml

ADD ./conf/context.xml /tmp/context.xml
ADD ./conf/server.xml /tmp/server.xml
ADD ./libs/openunison-tmp-0.0.1-SNAPSHOT.jar /tmp/openunison-tmp-0.0.1-SNAPSHOT.jar

RUN set -x \
	&& curl -fSL "$TOMCAT_TGZ_URL" -o tomcat.tar.gz \
	&& curl -fSL "$TOMCAT_TGZ_URL.asc" -o tomcat.tar.gz.asc \
	&& gpg --verify tomcat.tar.gz.asc \
	&& tar -xvf tomcat.tar.gz --strip-components=1 \
	&& rm bin/*.bat \
	&& rm tomcat.tar.gz* ; \
  rm -rf /usr/local/tomcat/webapps/* ; \
  wget $OPEN_UNISON_WAR_URL -O /tmp/openunison.zip ; \
  mkdir /usr/local/tomcat/webapps/ROOT ; \
  unzip /tmp/openunison.zip -d /usr/local/tomcat/webapps/ROOT/ ; \
  rm /usr/local/tomcat/webapps/ROOT/WEB-INF/log4j.xml ; \
  cp /tmp/context.xml /usr/local/tomcat/webapps/ROOT/META-INF/context.xml ; \
  cp /tmp/server.xml /usr/local/tomcat/conf/server.xml ; \
  cp /tmp/openunison-tmp-0.0.1-SNAPSHOT.jar /usr/local/tomcat/webapps/ROOT/WEB-INF/lib ; \
  rm -rf /tmp/openunison.zip ; \
  wget http://search.maven.org/remotecontent?filepath=mysql/mysql-connector-java/5.1.38/mysql-connector-java-5.1.38.jar -O /usr/local/tomcat/webapps/ROOT/WEB-INF/lib/mysql-connector-java-5.1.38.jar ; \
  wget $OPENUNISON_WS_WEBXML -O /usr/local/tomcat/webapps/ROOT/WEB-INF/web.xml ; \
  chmod -R o+rw /usr/local/tomcat ; \
  chmod -R o+rw /var/lib/unison-activemq

CMD ["catalina.sh", "run"]
