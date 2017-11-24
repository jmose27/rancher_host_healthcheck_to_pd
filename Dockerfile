FROM ubuntu:16.04 

RUN apt update && \
	apt install -y ruby-full
ENV PATH /usr/bin:$PATH

COPY ./rancher_health_check.rb /srv/rancher_health_check.rb
COPY ./entrypoint.sh /srv/entrypoint.sh
RUN chmod +x /srv/entrypoint.sh
ENTRYPOINT '/srv/entrypoint.sh'