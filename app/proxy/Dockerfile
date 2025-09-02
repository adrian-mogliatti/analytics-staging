FROM nginx:alpine
RUN apk add --no-cache apache2-utils bash
COPY default.conf /etc/nginx/conf.d/default.conf
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
ENV BASIC_AUTH_USER=""
ENV BASIC_AUTH_PASS=""
EXPOSE 80
ENTRYPOINT ["/entrypoint.sh"]

