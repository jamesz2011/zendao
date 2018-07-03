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

ENV ZENDAO_VERSION="10.0"

ENV	ZENDAO_DOWNLOAD_URL  http://dl.cnezsoft.com/zentao/${ZENDAO_VERSION}/ZenTaoPMS.${ZENDAO_VERSION}.stable.zbox_64.tar.gz
RUN    cd /opt  \
        && wget    ${ZENDAO_DOWNLOAD_URL} \
         &&  tar -xzf /opt/ZenTaoPMS.${ZENDAO_VERSION}.stable.zbox_64.tar.gz \
       && rm /opt/ZenTaoPMS.${ZENDAO_VERSION}.stable.zbox_64.tar.gz

RUN /opt/zbox/zbox -ap 8080  \
    && /opt/zbox/zbox -mp 3306



RUN /opt/zbox/zbox stop
RUN /opt/zbox/zbox start



EXPOSE 8080 3306


