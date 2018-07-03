FROM ubuntu:16.04
MAINTAINER jamesz2011 <jamesz2011@126.com>

COPY ./sources.list /opt
WORKDIR /opt
RUN cp -vf sources.list /etc/apt/

RUN apt-get update \
    && apt-get install -y apt-transport-https  vim lrzsz tzdata sudo wget curl  dos2unix openssh-server  gcc make \
	&& service ssh restart
#init ubuntu16.04
COPY ./init_ubuntu1604_stable.sh /opt

#RUN wget -P /opt http://git.chinafintech.cn/yecuihao/APITestEnv_shell/raw/master/init_ubuntu1604_stable.sh

RUN dos2unix /opt/init_ubuntu1604_stable.sh
RUN chmod a+x /opt/init_ubuntu1604_stable.sh
RUN . /opt/init_ubuntu1604_stable.sh

#install jdk 

ENV JDK_VERSION="1.8.0_131"

ENV	JAVA_DOWNLOAD_URL  http://download.oracle.com/otn-pub/java/jdk/8u131-b11/d54c1d3a095b4ff2b6607d096fa80163/jdk-8u131-linux-x64.tar.gz

RUN    cd /opt  \
        && wget  --header "Cookie: oraclelicense=accept-securebackup-cookie"  ${JAVA_DOWNLOAD_URL} \
         &&  tar -xzf /opt/jdk-8u131-linux-x64.tar.gz \
       && rm /opt/jdk-8u131-linux-x64.tar.gz

RUN ln -s ${JAVA_HOME}/bin/java /usr/local/bin/java \
    && ln -s ${JAVA_HOME}/bin/javac   /usr/local/bin/javac


ENV JAVA_HOME /opt/jdk${JDK_VERSION}
ENV JRE_HOME ${JAVA_HOME}/jre
ENV CLASSPATH .:${JAVA_HOME}/lib:${JRE_HOME}/lib
ENV PATH ${JAVA_HOME}/bin:$PATH 

#install maven

ENV MAVEN_VERSION="3.5.3"
ENV MAVEN_DOWNLOAD_URL  http://www-us.apache.org/dist/maven/maven-3/${MAVEN_VERSION}/binaries/apache-maven-${MAVEN_VERSION}-bin.tar.gz


RUN cd /opt  \
    && wget  ${MAVEN_DOWNLOAD_URL}   \
    &&  tar -xzf apache-maven-$MAVEN_VERSION-bin.tar.gz \ 
    && rm apache-maven-$MAVEN_VERSION-bin.tar.gz 

RUN ln -s ${MAVEN_HOME}/bin/mvn /usr/local/bin/mvn


ENV MAVEN_HOME /opt/apache-maven-$MAVEN_VERSION 
ENV PATH ${MAVEN_HOME}/bin:$PATH
RUN cp -fv ${MAVEN_HOME}/conf/settings.xml ${MAVEN_HOME}/conf/settings.xml.bak

COPY ./settings.xml ${MAVEN_HOME}/conf/

#install jmeter


ENV JMETER_VERSION="3.3"

ENV  JMETER_DOWNLOAD_URL   https://archive.apache.org/dist/jmeter/binaries/apache-jmeter-${JMETER_VERSION}.tgz

RUN  cd /opt \
     && wget  ${JMETER_DOWNLOAD_URL}  \
     && tar -xzf apache-jmeter-${JMETER_VERSION}.tgz \
     && rm /opt/apache-jmeter-${JMETER_VERSION}.tgz


RUN ln -s ${JMETER_HOME}/bin/jmeter /usr/local/bin/jmeter

# Set global PATH such that "jmeter" command is found
ENV JMETER_HOME /opt/apache-jmeter-${JMETER_VERSION} 
ENV JMETER_BIN  ${JMETER_HOME}/bin 
ENV PATH ${JMETER_BIN}:$PATH


#install python3

ENV PYTHON_VERSION="3.5.4"

ENV PYTHON_DOWNLOAD_URL https://www.python.org/ftp/python/${PYTHON_VERSION}/Python-${PYTHON_VERSION}.tar.xz
ENV PYTHON_HOME /opt/python3/Python-${PYTHON_VERSION}
RUN  cd /opt \
	 && mkdir /opt/python3 \
     && wget  ${PYTHON_DOWNLOAD_URL}  \
     && tar xf Python-${PYTHON_VERSION}.tar.xz -C /opt/python3 

RUN   cd /opt/python3/Python-${PYTHON_VERSION} \
     && ./configure --prefix=${PYTHON_HOME} \ 
     && make \
     && make install  \
     && ln -s ${PYTHON_HOME}/bin/python3.5  /usr/local/bin/python3 \
     && rm /opt/Python-${PYTHON_VERSION}.tar.xz

RUN chmod a+x ~/.bashrc \
     && echo "alias python='python3'" >> ~/.bashrc \
     && apt-get update && apt-get install -y  python3-pip \
     && echo "alias pip='pip3'" >> ~/.bashrc 



RUN apt-get update && apt-get install -y git curl && rm -rf /var/lib/apt/lists/*

ARG user=jenkins
ARG group=jenkins
ARG uid=1000
ARG gid=1000
ARG http_port=8080
ARG agent_port=50000
ARG JENKINS_HOME=/var/jenkins_home

ENV JENKINS_HOME $JENKINS_HOME
ENV JENKINS_SLAVE_AGENT_PORT ${agent_port}

# Jenkins is run with user `jenkins`, uid = 1000
# If you bind mount a volume from the host or a data container,
# ensure you use the same uid
RUN mkdir -p $JENKINS_HOME \
    && chown ${uid}:${gid} $JENKINS_HOME \
    && groupadd -g ${gid} ${group} \
    && useradd -d "$JENKINS_HOME" -u ${uid} -g ${gid} -m -s /bin/bash ${user}

# Jenkins home directory is a volume, so configuration and build history
# can be persisted and survive image upgrades
VOLUME $JENKINS_HOME

# `/usr/share/jenkins/ref/` contains all reference configuration we want
# to set on a fresh new installation. Use it to bundle additional plugins
# or config file with your custom jenkins Docker image.
RUN mkdir -p /usr/share/jenkins/ref/init.groovy.d

# Use tini as subreaper in Docker container to adopt zombie processes
ARG TINI_VERSION=v0.16.1
COPY tini_pub.gpg ${JENKINS_HOME}/tini_pub.gpg
RUN curl -fsSL https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini-static-$(dpkg --print-architecture) -o /sbin/tini \
  && curl -fsSL https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini-static-$(dpkg --print-architecture).asc -o /sbin/tini.asc \
  && gpg --import ${JENKINS_HOME}/tini_pub.gpg \
  && gpg --verify /sbin/tini.asc \
  && rm -rf /sbin/tini.asc /root/.gnupg \
  && chmod +x /sbin/tini

COPY init.groovy /usr/share/jenkins/ref/init.groovy.d/tcp-slave-agent-port.groovy

# jenkins version being bundled in this docker image
ARG JENKINS_VERSION
ENV JENKINS_VERSION ${JENKINS_VERSION:-2.107.2}

# jenkins.war checksum, download will be validated using it
#ARG JENKINS_SHA=2d71b8f87c8417f9303a73d52901a59678ee6c0eefcf7325efed6035ff39372a

# Can be used to customize where jenkins.war get downloaded from
ARG JENKINS_URL=https://repo.jenkins-ci.org/public/org/jenkins-ci/main/jenkins-war/${JENKINS_VERSION}/jenkins-war-${JENKINS_VERSION}.war

# could use ADD but this one does not check Last-Modified header neither does it allow to control checksum
# see https://github.com/docker/docker/issues/8331
RUN curl -fsSL ${JENKINS_URL} -o /usr/share/jenkins/jenkins.war 
 # && echo "${JENKINS_SHA}  /usr/share/jenkins/jenkins.war" | sha256sum -c -

ENV JENKINS_UC https://updates.jenkins.io
ENV JENKINS_UC_EXPERIMENTAL=https://updates.jenkins.io/experimental
RUN chown -R ${user} "$JENKINS_HOME" /usr/share/jenkins/ref

# for main web interface:
EXPOSE ${http_port}

# will be used by attached slave agents:
EXPOSE ${agent_port}

ENV COPY_REFERENCE_FILE_LOG $JENKINS_HOME/copy_reference_file.log

USER ${user}

COPY jenkins-support /usr/local/bin/jenkins-support
COPY jenkins.sh /usr/local/bin/jenkins.sh
COPY tini-shim.sh /bin/tini
ENTRYPOINT ["/sbin/tini", "--", "/usr/local/bin/jenkins.sh"]

# from a derived Dockerfile, can use `RUN plugins.sh active.txt` to setup /usr/share/jenkins/ref/plugins from a support bundle
COPY plugins.sh /usr/local/bin/plugins.sh
COPY install-plugins.sh /usr/local/bin/install-plugins.sh





#EXPOSE 8080 50000


