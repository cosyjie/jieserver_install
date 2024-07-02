PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

if [ $(whoami) != "root" ];then
	echo "请使用root用户执行安装脚本！"
	exit 1;
fi

check64bit=$(getconf LONG_BIT)
if [ "${check64bit}" != '64' ];then
	echo "不支持32位系统，请使用64位系统安装!";
	exit 1;
fi

setenforce 0
sed -i 's/^SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config

timedatectl set-timezone Asia/Shanghai
timedatectl set-ntp yes

yum install -y https://mirrors.aliyun.com/epel/epel-release-latest-8.noarch.rpm
sed -i 's|^#baseurl=https://download.example/pub|baseurl=https://mirrors.aliyun.com|' /etc/yum.repos.d/epel*
sed -i 's|^metalink|#metalink|' /etc/yum.repos.d/epel*

yum clean all
yum makecache

dnf install tar wget make gcc patch zlib-devel bzip2 bzip2-devel readline-devel sqlite sqlite-devel openssl-devel tk-devel libffi-devel xz-devel libuuid-devel gdbm-libs libnsl2 python3-devel mysql-devel pkgconfig unzip -y

wget -O jieserver_base.zip https://github.com/cosyjie/jieserver_base/archive/refs/heads/main.zip
 
unzip jieserver_base.zip -d /opt
mv /opt/jieserver_base-main /opt/jieserver

tar -zxvf /opt/jieserver/install/pyenv.tar.gz -C /opt/jieserver/
mv /opt/jieserver/pyenv-2.4.0 /opt/jieserver/pyenv

tar -zxvf /opt/jieserver/install/pyenv-virtualenv.tar.gz -C /opt/jieserver/pyenv/plugins
mv /opt/jieserver/pyenv/plugins/pyenv-virtualenv-1.2.3 /opt/jieserver/pyenv/plugins/pyenv-virtualenv

echo 'export PYTHON_BUILD_MIRROR_URL_SKIP_CHECKSUM=1' >> ~/.bashrc
echo 'export PYTHON_BUILD_MIRROR_URL="https://mirrors.huaweicloud.com/python/"' >> ~/.bashrc
echo 'export PYENV_ROOT="/opt/jieserver/pyenv"' >> ~/.bashrc
echo 'command -v pyenv >/dev/null || export PATH="$PYENV_ROOT/bin:$PATH"' >> ~/.bashrc
echo 'eval "$(pyenv init -)"' >> ~/.bashrc
echo 'eval "$(pyenv virtualenv-init -)"' >> ~/.bashrc

echo 'export PYTHON_BUILD_MIRROR_URL_SKIP_CHECKSUM=1' >> ~/.bash_profile
echo 'export PYTHON_BUILD_MIRROR_URL="https://mirrors.huaweicloud.com/python/"' >> ~/.bash_profile
echo 'export PYENV_ROOT="/opt/jieserver/pyenv"' >> ~/.bash_profile
echo 'command -v pyenv >/dev/null || export PATH="$PYENV_ROOT/bin:$PATH"' >> ~/.bash_profile
echo 'eval "$(pyenv init -)"' >> ~/.bash_profile

source ~/.bashrc
source ~/.bash_profile

mkdir /opt/jieserver/pyenv/cache
mv /opt/jieserver/install/Python-3.11.9.tar.xz /opt/jieserver/pyenv/cache/

/opt/jieserver/pyenv/libexec/pyenv install 3.11.9 -v
/opt/jieserver/pyenv/libexec/pyenv virtualenv 3.11.9 jieadminpanel3119

/opt/jieserver/pyenv/versions/jieadminpanel3119/bin/pip config set global.index-url https://pypi.tuna.tsinghua.edu.cn/simple
/opt/jieserver/pyenv/versions/jieadminpanel3119/bin/pip install django~=4.2
/opt/jieserver/pyenv/versions/jieadminpanel3119/bin/pip install psutil
/opt/jieserver/pyenv/versions/jieadminpanel3119/bin/pip install requests
/opt/jieserver/pyenv/versions/jieadminpanel3119/bin/pip install cryptography

/opt/jieserver/pyenv/versions/jieadminpanel3119/bin/python /opt/jieserver/jieadminpanel/manage.py makemigrations
/opt/jieserver/pyenv/versions/jieadminpanel3119/bin/python /opt/jieserver/jieadminpanel/manage.py migrate

firewall-cmd --add-port=8000/tcp --permanent
firewall-cmd --reload

/opt/jieserver/pyenv/versions/jieadminpanel3119/bin/python /opt/jieserver/jieadminpanel/manage.py encryptionkey
/opt/jieserver/pyenv/versions/jieadminpanel3119/bin/python /opt/jieserver/jieadminpanel/manage.py createadmin

/opt/jieserver/pyenv/versions/jieadminpanel3119/bin/python /opt/jieserver/jieadminpanel/manage.py loaddata /opt/jieserver/install/appstore_appsinfo.json


IP=$(hostname -I | awk -F " " '{printf $1}')
echo "请访问 http://$IP:8000 来启动系统"

exec "$SHELL"
