# Pull base image.
FROM amitanandj/javadockerfile
MAINTAINER Amit Anand <amitanandj@hotmail.com>

# Install ElasticSearch.
RUN \
  cd /tmp && \
  wget https://download.elasticsearch.org/elasticsearch/elasticsearch/elasticsearch-1.2.1.tar.gz && \
  tar xvzf elasticsearch-1.2.1.tar.gz && \
  rm -f elasticsearch-1.2.1.tar.gz && \
  mv /tmp/elasticsearch-1.2.1 /elasticsearch

# Install Fluentd.
RUN curl https://packages.treasuredata.com/GPG-KEY-td-agent | apt-key add -
RUN echo "deb http://packages.treasuredata.com/2/ubuntu/precise/ precise contrib" > /etc/apt/sources.list.d/treasure-data.list
RUN    apt-get update
RUN apt-get clean

RUN apt-get -y install curl libcurl4-openssl-dev ruby ruby-dev make build-essential

RUN gem install fluentd fluent-plugin-elasticsearch --no-ri --no-rdoc
RUN fluentd --setup ./fluent

# Copy fluentd config
ADD config/etc/fluent/fluent.conf /etc/td-agent/td-agent.conf

RUN apt-get install -y software-properties-common

RUN apt-key adv --keyserver hkp://pgp.mit.edu:80 --recv-keys 573BFD6B3D8FBC641079A6ABABF5BD827BD9BF62
RUN echo "deb http://nginx.org/packages/mainline/debian/ jessie nginx" >> /etc/apt/sources.list

ENV NGINX_VERSION 1.9.6-1~jessie

RUN apt-get update && \
    apt-get install -y ca-certificates nginx=${NGINX_VERSION}
    #&& \
    #rm -rf /var/lib/apt/lists/*

# forward request and error logs to docker log collector
RUN ln -sf /dev/stdout /var/log/nginx/access.log
RUN ln -sf /dev/stderr /var/log/nginx/error.log

VOLUME ["/var/cache/nginx"]

# Replace nginx default site with Kibana, making it accessible on localhost:80.
ADD config/etc/nginx/kibana.conf /etc/nginx/nginx.conf

# CMD ["nginx", "-g", "daemon off;"]
CMD nginx

# Install Kibana.
RUN \
  cd /tmp && \
  wget https://download.elasticsearch.org/kibana/kibana/kibana-3.1.0.tar.gz && \
  tar xvzf kibana-3.1.0.tar.gz && \
  rm -f kibana-3.1.0.tar.gz && \
  mv kibana-3.1.0 /usr/share/kibana

# Copy kibana config.
ADD config/etc/kibana/config.js /usr/share/kibana/config.js

# Install supervisord.

RUN apt-get install -y --no-install-recommends supervisor

# Copy supervisor config.
ADD config/etc/supervisor/supervisord.conf /etc/supervisor/supervisord.conf

# Needed for configuring basic authentication the first time
RUN apt-get install apache2-utils

#CMD ["fluentd", "--conf=/etc/fluent/fluent.conf"]


# Define mountable directories.
VOLUME ["/data", "/var/log", "/etc/nginx/sites-enabled"]

# Define working directory.
WORKDIR /

# Set default command to supervisor.
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/supervisord.conf"]

ADD config/etc/elasticsearch/elasticsearch.yml /elasticsearch/config/elasticsearch.yml

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
