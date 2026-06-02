FROM httpd:2.4


RUN apt-get update && apt-get install -y git

RUN git clone https://github.com/Eduardo9d/Projects/tree/7b1addc4f22391f4a8a63aab0300bd66ff14b358/docker/apache/HTML5-Template /usr/local/apache2/htdocs/

EXPOSE 80

CMD ["httpd-foreground"]
