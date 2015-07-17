Docker-Fluentd-Kibana
====================

## Log analitycs using Fluentd, Elasticsearch and Kibana

This container comes built with Fluentd for log processing, Elasticsearch for log storeage and Kibana for log analytics.
Nginx is also installed and configured for Kibana.  Supervisord is used for Nginx, Fluentd, and Elasticsearch.

After installing you can visit http://localhost to view the Kibana web interface.
Fluentd will be running and accepting messages on port 24224.  You can then start posting messages to Fluentd and they will be saved in Elasticsearch.

## Exposed ports

 - 80 Nginx http
 - 9200 Elasticsearch http
 - 9300 Elasticsearch transport
 - 24224 Fluentd

Nginx is confirgured to proxy elastic search port 9200 to 80 which avoids some proxies blocking high ports.
Kibana comes shipped with a config to use port 80 for elastic search so its ready to go.

## Default command

Supervisord - Start Nginx, Elasticsearch, and Fluentd in the foreground with supervisord.

## Volumes

 - /data - Elasticsearch
 - /var/log - Nginx, Fluentd, Elasticsearch

## Running the image

First step is to build the image

    docker build -t starmind/log_fluentd_kibana .

Run the image:

Note you may want to change the volume -v parameter to set a different data directory used by Elasticsearch.

    sudo docker run -p 9200:9200 -p 9300:9300 -p 24224:24224 -p 8080:80 -v /var/data/log_index:/data  --name fluentd_kibana_inst -i -t sstarmind/log_fluentd_kibana

Running with systemd:
    
 - copy to `systemd.fluentd-kibana.service` to  `/etc/systemd/system`
 - `sudo systemctl enable /etc/systemd/system/systemd.fluentd-kibana.service`
 - `sudo systemctl start systemd.fluentd-kibana.service`


