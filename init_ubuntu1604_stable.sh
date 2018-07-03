
#!/bin/bash

#这个shell用于当安装完Ubuntu后安装Ubuntu工具软件使用

echo "run this shell that you must under root" 




#sudo wget http://code.taobao.org/p/ubuntu/src/trunk/sources.list?orig

#mv sources.list?orig sources.list
#wget https://coding.net/u/jamesz2011/p/ubuntu_lib/git/raw/master/source/16.04/sources.list
#cp -vf sources.list /etc/apt/

apt-get update
apt-get install -y  python-software-properties software-properties-common

apt-get install -y  sysv-rc-conf 

#sudo apt-get install -y openssh-server


ufw disable
 

echo "安装中文字体"
apt-get install -y --force-yes --no-install-recommends fonts-wqy-microhei

apt-get install -y --force-yes --no-install-recommends ttf-wqy-zenhei

echo "------install git ----" 

apt-get update
#sudo apt-get install -y python-software-properties software-properties-common
#sudo apt-get update

apt-get install -y git  
#sudo git -version

#git config --global.user.name "xxx"
#git config --global.user.email "xxxx1@126.com"

git config --global http.postBuffer 524288000  


#dpkg-reconfigure tzdata

echo "----setting date at shanghai-----"

ln -fs /usr/share/zoneinfo/Asia/Shanghai /etc/localtime 
dpkg-reconfigure --frontend noninteractive tzdata

