# Pull base image.
FROM java:8
MAINTAINER Harley Bussell <modmac@gmail.com>

# Install ElasticSearch.
RUN \
  cd /tmp && \
  wget https://download.elasticsearch.org/elasticsearch/elasticsearch/elasticsearch-1.2.1.tar.gz && \
  tar xvzf elasticsearch-1.2.1.tar.gz && \
  rm -f elasticsearch-1.2.1.tar.gz && \
  mv /tmp/elasticsearch-1.2.1 /elasticsearch

# Install Fluentd.
RUN curl https://packages.treasuredata.com/GPG-KEY-td-agent | apt-key add - && \
echo "deb http://packages.treasuredata.com/2/ubuntu/precise/ precise contrib" > /etc/apt/sources.list.d/treasure-data.list && \
apt-get update && \
apt-get install -y --force-yes td-agent
RUN td-agent --setup=/etc/fluent && \
    mkdir -p /var/log/fluent

# add fluent plugins
RUN /usr/sbin/td-agent-gem install fluent-plugin-secure-forward && /usr/sbin/td-agent-gem install fluent-plugin-elasticsearch

# copy fluent config
ADD config/etc/fluent/fluent.conf /etc/fluent/fluent.conf

# Install Nginx.
RUN \
  apt-get install -y nginx && \
  echo "\ndaemon off;" >> /etc/nginx/nginx.conf && \
  chown -R www-data:www-data /var/lib/nginx

# Replace nginx default site with Kibana, making it accessible on localhost:80.
RUN unlink /etc/nginx/sites-enabled/default
ADD config/etc/nginx/kibana.conf /etc/nginx/sites-enabled/default

# Install Kibana.
RUN \
  cd /tmp && \
  wget https://download.elasticsearch.org/kibana/kibana/kibana-3.1.0.tar.gz && \
  tar xvzf kibana-3.1.0.tar.gz && \
  rm -f kibana-3.1.0.tar.gz && \
  mv kibana-3.1.0 /usr/share/kibana

#RUN cp -R /usr/share/kibana/* /

# Copy kibana config.
ADD config/etc/kibana/config.js /usr/share/kibana/config.js

# Install supervisord.

RUN apt-get install -y --no-install-recommends supervisor

# Copy supervisor config.
ADD config/etc/supervisor/supervisord.conf /etc/supervisor/supervisord.conf

# Define mountable directories.
VOLUME ["/data", "/var/log", "/etc/nginx/sites-enabled"]

# Define working directory.
WORKDIR /
# Define default command.
#CMD ["/elasticsearch/bin/elasticsearch"]


# Set default command to supervisor.
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/supervisord.conf"]

# Expose Elasticsearch ports.
#   - 9200: HTTP
#   - 9300: transport
EXPOSE 9200
EXPOSE 9300

# Expose Fluentd port.
EXPOSE 24224

# Expose nginx http ports
EXPOSE 80
EXPOSE 443


