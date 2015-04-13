FROM debian:jessie

MAINTAINER Yvonnick Esnault <yvonnick@esnau.lt>

ENV DEBIAN_FRONTEND noninteractive 
ENV DEBCONF_NONINTERACTIVE_SEEN true

# Install some tools, Supervisor, MySQL, apache, php and vsc binaries
RUN apt-get update && apt-get install -y \
	ssh \
	wget \
	vim \
	less \
	zip \
	cron \
	lsof \
	sudo \
	screen \
	supervisor \
	mysql-server \
	mysql-client \
	libmysqlclient-dev \
	apache2 \
	php5 \
	libapache2-mod-php5 \
	php5-acpu \
	php5-mcrypt \
	php5-mysql \
	php5-gd \
	php5-dev \
	php5-curl \
	php5-cli \
	php5-json \
	php5-ldap \
	git \
	subversion \
	mercurial \
	postfix \
	python-pygments

RUN cd /opt/ && git clone https://github.com/facebook/libphutil.git
RUN cd /opt/ && git clone https://github.com/facebook/arcanist.git
RUN cd /opt/ && git clone https://github.com/facebook/phabricator.git

RUN apt-get clean

# Get Utils
RUN mkdir -p /var/run/sshd
RUN useradd -d /home/admin -m -s /bin/bash admin
RUN echo 'admin:docker' | chpasswd
RUN echo 'root:docker' | chpasswd
RUN echo 'admin ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers.d/admin
RUN chmod 0440 /etc/sudoers.d/admin


# Enabled mod rewrite for phabricator
RUN a2enmod rewrite && a2enmod headers && a2enmod ssl
#RUN sed -i -e"s/^bind-address\s*=\s*127.0.0.1/bind-address = 0.0.0.0/" /etc/mysql/my.cnf
RUN sed -i 's/\[mysqld\]/[mysqld]\nsql_mode=STRICT_ALL_TABLES/' /etc/mysql/my.cnf
ADD ./startup.sh /opt/startup.sh
RUN chmod +x /opt/startup.sh

ADD phabricator.conf /etc/apache2/sites-available/phabricator.conf
RUN ln -s /etc/apache2/sites-available/phabricator.conf /etc/apache2/sites-enabled/phabricator.conf
RUN rm -f /etc/apache2/sites-enabled/000-default.conf

RUN ulimit -c 10000

# Fix diffusion SSH access
RUN \
	useradd -ms /bin/bash git && \
	passwd -d git && \
	useradd -s /bin/false phd && \
	echo "git ALL=(phd) SETENV: NOPASSWD: $(command -v git-upload-pack), $(command -v git-receive-pack), $(command -v hg), $(command -v svnserve)" >> /etc/sudoers && \
	cp -v /opt/phabricator/resources/sshd/phabricator-ssh-hook.sh /usr/sbin/ && \
	chown root /usr/sbin/phabricator-ssh-hook.sh && \
	chmod 755 /usr/sbin/phabricator-ssh-hook.sh && \
	sed -i 's/vcs-user/git/g' /usr/sbin/phabricator-ssh-hook.sh && \
	sed -i 's~ROOT=.*~ROOT="/opt/phabricator"~' /usr/sbin/phabricator-ssh-hook.sh && \
	cp /opt/phabricator/resources/sshd/sshd_config.phabricator.example /opt/phabricator/resources/sshd/sshd_config.phabricator && \
	sed -i 's~^AuthorizedKeysCommand .*$~AuthorizedKeysCommand /usr/sbin/phabricator-ssh-hook.sh~' /opt/phabricator/resources/sshd/sshd_config.phabricator && \
	sed -i 's/vcs-user/git/g' /opt/phabricator/resources/sshd/sshd_config.phabricator

RUN mkdir -p '/var/repo/' && chown -R git /var/repo

# Fix phabriactor settings
RUN  sed 's/post_max_size = 8M/post_max_size = 32M/' /etc/php5/apache2/php.ini && \
	sed -i 's/opcache.validate_timestamps=1/opcache.validate_timestamps=0/' /etc/php5/apache2/php.ini
# Fix MySQL settings
RUN sed -i '/\[mysqld\]/a ft_stopword_file=/opt/phabricator/resources/sql/stopwords.txt\nft_min_word_len=3\nft_boolean_syntax=" |-><()~*:\"\"&^"\ninnodb_buffer_pool_size=1600M' /etc/mysql/my.cnf

VOLUME /opt/phabricator/conf/local
EXPOSE 443 80 22

CMD ["/opt/startup.sh"]
