sudo apt update
sudo apt install -y gcc vim curl wget g++ libcairo2-dev libjpeg-turbo8-dev libpng-dev \
libtool-bin libossp-uuid-dev libavcodec-dev libavutil-dev libswscale-dev build-essential \
libpango1.0-dev libssh2-1-dev libvncserver-dev libtelnet-dev \
libssl-dev libvorbis-dev libwebp-dev

echo Installing FreeRDP2
sudo add-apt-repository ppa:remmina-ppa-team/remmina-next-daily
sudo apt update
sudo apt install freerdp2-dev freerdp2-x11 -y

sudo apt install openjdk-11-jdk

echo Adding tomcat user...
sudo useradd -m -U -d /opt/tomcat -s /bin/false tomcat

echo Installing Tomcat...
wget https://downloads.apache.org/tomcat/tomcat-9/v9.0.60/bin/apache-tomcat-9.0.60.tar.gz -P ~
sudo mkdir /opt/tomcat
sudo tar -xzf apache-tomcat-9.0.60.tar.gz -C /opt/tomcat/
sudo mv /opt/tomcat/apache-tomcat-9.0.60 /opt/tomcat/tomcatapp
sudo chown -R tomcat: /opt/tomcat
sudo chmod +x /opt/tomcat/tomcatapp/bin/*.sh
sudo touch /etc/systemd/system/tomcat.service
echo "[Unit]" >> /etc/systemd/system/tomcat.service
echo "Description=Tomcat 9 servlet container" >> /etc/systemd/system/tomcat.service
echo "After=network.target" >> /etc/systemd/system/tomcat.service
echo "[Service]" >> /etc/systemd/system/tomcat.service
echo "Type=forking" >> /etc/systemd/system/tomcat.service
echo "User=tomcat" >> /etc/systemd/system/tomcat.service
echo "Group=tomcat" >> /etc/systemd/system/tomcat.service
echo Environment="JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd6" >> /etc/systemd/system/tomcat.service
echo Environment="JAVA_OPTS=-Djava.security.egd=file:///dev/urandom -Djava.awt.headless=true" >> /etc/systemd/system/tomcat.service
echo Environment="CATALINA_BASE=/opt/tomcat/tomcatapp" >> /etc/systemd/system/tomcat.service
echo Environment="CATALINA_HOME=/opt/tomcat/tomcatapp" >> /etc/systemd/system/tomcat.service
echo Environment="CATALINA_PID=/opt/tomcat/tomcatapp/temp/tomcat.pid" >> /etc/systemd/system/tomcat.service
echo Environment="CATALINA_OPTS=-Xms512M -Xmx1024M -server -XX:+UseParallelGC" >> /etc/systemd/system/tomcat.service
echo ExecStart=/opt/tomcat/tomcatapp/bin/startup.sh >> /etc/systemd/system/tomcat.service
echo ExecStop=/opt/tomcat/tomcatapp/bin/shutdown.sh >> /etc/systemd/system/tomcat.service
echo [Install] >> /etc/systemd/system/tomcat.service
echo WantedBy=multi-user.target >> /etc/systemd/system/tomcat.service

sudo systemctl daemon-reload
sudo systemctl enable --now tomcat

sudo ufw allow 8080/tcp

echo Downloading Guacamole...
wget https://downloads.apache.org/guacamole/1.4.0/source/guacamole-server-1.4.0.tar.gz -P ~
tar xzf ~/guacamole-server-1.4.0.tar.gz
cd ~/guacamole-server-1.4.0
./configure --with-init-dir=/etc/init.d
make
sudo make install
sudo ldconfig
sudo systemctl daemon-reload
sudo systemctl start guacd
sudo systemctl enable guacd

echo Installing Guac Client...
sudo mkdir /etc/guacamole
wget https://downloads.apache.org/guacamole/1.4.0/binary/guacamole-1.4.0.war -P ~
sudo mv ~/guacamole-1.4.0.war /etc/guacamole/guacamole.war
sudo ln -s /etc/guacamole/guacamole.war /opt/tomcat/tomcatapp/webapps

echo "GUACAMOLE_HOME=/etc/guacamole" | sudo tee -a /etc/default/tomcat
sudo touch /etc/guacamole/guacamole.properties
echo "guacd-hostname: localhost" >> /etc/guacamole/guacamole.properties
echo "guacd-port:    4822" >> /etc/guacamole/guacamole.properties
echo "user-mapping:    /etc/guacamole/user-mapping.xml" >> /etc/guacamole/guacamole.properties
echo "auth-provider:    net.sourceforge.guacamole.net.basic.BasicFileAuthenticationProvider" >> /etc/guacamole/guacamole.properties

sudo ln -s /etc/guacamole /opt/tomcat/tomcatapp/.guacamole

