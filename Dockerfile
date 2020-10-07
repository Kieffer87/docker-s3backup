FROM alpine:latest

RUN apk update && \
  apk add --no-cache bash py3-pip python3 py3-magic py3-dateutil

RUN pip install s3cmd && \
  rm -rf /tmp/pip_build_root/

RUN mkdir -p /backup

ADD s3cmd.cfg /root/.s3cfg
ADD run.sh /

ENTRYPOINT ["/run.sh"]
CMD ["start"]
