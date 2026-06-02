FROM httpd:2.4

# Copy site files from build context (expects build context to be repository root)
COPY HTML5-Template/ /usr/local/apache2/htdocs/

EXPOSE 80

CMD ["httpd-foreground"]
