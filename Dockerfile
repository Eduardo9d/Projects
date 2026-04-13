FROM ubuntu:22.04
RUN apt -y update
RUN apt -y install apache2
RUN echo "Melhor Site" > /var/www/html/index.html
EXPOSE 80