# Pull base image.
FROM amitanandj/javadockerfile
MAINTAINER Amit Anand <amitanandj@hotmail.com>

RUN apt-get update
RUN apt-get -y install curl libcurl4-openssl-dev ruby ruby-dev make build-essential
# Install ElasticSearch.
RUN \
  cd /tmp && \
  wget https://download.elasticsearch.org/elasticsearch/release/org/elasticsearch/distribution/tar/elasticsearch/2.1.1/elasticsearch-2.1.1.tar.gz && \
  tar xvzf elasticsearch-2.1.1.tar.gz && \
  rm -f elasticsearch-2.1.1.tar.gz && \
  mv /tmp/elasticsearch-2.1.1 /elasticsearch


RUN apt-get clean

# Install Fluentd.
RUN echo "deb http://packages.treasure-data.com/precise/ precise contrib" > /etc/apt/sources.list.d/treasure-data.list && \
    apt-get update && \
    apt-get install -y --force-yes libssl0.9.8 software-properties-common td-agent && \
    apt-get clean
ENV GEM_HOME /usr/lib/fluent/ruby/lib/ruby/gems/1.9.1/
ENV GEM_PATH /usr/lib/fluent/ruby/lib/ruby/gems/1.9.1/
ENV PATH /usr/lib/fluent/ruby/bin:$PATH
RUN fluentd --setup=/etc/fluent && \
    /usr/lib/fluent/ruby/bin/fluent-gem install fluent-plugin-elasticsearch \
    fluent-plugin-secure-forward fluent-plugin-record-reformer fluent-plugin-exclude-filter && \
    mkdir -p /var/log/fluent

# Copy fluentd config
ADD config/etc/fluent/fluent.conf /etc/td-agent/td-agent.conf
ADD config/etc/fluent/fluent.conf /etc/fluent/fluent.conf


# Install Nginx.
RUN \
  add-apt-repository -y ppa:nginx/stable && \
  apt-get update && \
  apt-get install -y nginx && \
  echo "\ndaemon off;" >> /etc/nginx/nginx.conf && \
  chown -R www-data:www-data /var/lib/nginx

# Replace nginx default site with Kibana, making it accessible on localhost:80.
RUN unlink /etc/nginx/sites-enabled/default
ADD config/etc/nginx/kibana.conf /etc/nginx/sites-enabled/default

# Install Kibana.
RUN \
  cd /tmp && \
  wget https://download.elastic.co/kibana/kibana/kibana-4.3.1-linux-x64.tar.gz && \
  tar xvzf kibana-4.3.1-linux-x64.tar.gz && \
  rm -f kibana-4.3.1-linux-x64.tar.gz && \
  mv kibana-4.3.1 /usr/share/kibana


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

# Set default command to supervisor.
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/supervisord.conf"]

# Expose Elasticsearch ports.
#   - 9200: HTTP
#   - 9300: transport
EXPOSE 9200
EXPOSE 9300

# Expose Fluentd port.
EXPOSE 24224
EXPOSE 8888

# Expose nginx http ports
EXPOSE 80
EXPOSE 443
