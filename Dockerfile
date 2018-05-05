FROM alpine:3.7

RUN apk add --no-cache mongodb && \
    rm /usr/bin/mongoperf

# copy initdb files
COPY docker-entrypoint-initdb.d /docker-entrypoint-initdb.d

VOLUME /data/db
EXPOSE 27017

COPY docker-entrypoint.sh /usr/bin/
ENTRYPOINT ["docker-entrypoint.sh"]

CMD ["mongod", "--bind_ip_all"]
