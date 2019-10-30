FROM alpine:3.9
# 3.10移除了Mongodb 在仓库中
# https://alpinelinux.org/posts/Alpine-3.10.0-released.html

RUN apk add --no-cache mongodb

# copy initdb files
COPY docker-entrypoint-initdb.d /docker-entrypoint-initdb.d

VOLUME /data/db
EXPOSE 27017

COPY docker-entrypoint.sh /usr/bin/
ENTRYPOINT ["docker-entrypoint.sh"]

CMD ["mongod", "--bind_ip_all"]
