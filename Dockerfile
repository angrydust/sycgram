FROM python:3.11-alpine
LABEL maintainer=angrydust

WORKDIR /sycgram
COPY . /sycgram

# The libc6-compat dependency is required to use the host's docker commands
RUN apk add --no-cache neofetch --repository=http://dl-cdn.alpinelinux.org/alpine/edge/testing/ \
    && apk add --no-cache libjpeg libwebp libpng py3-lxml bc libc6-compat git vim fish \
    && apk add --no-cache --virtual build-deps gcc g++ zlib-dev jpeg-dev libxml2-dev libxslt-dev libwebp-dev libpng-dev \
    && pip install -r requirements.txt --no-cache-dir \
    && apk del build-deps \
    && mkdir -p /sycgram/data \
    && rm -rf .git .github .gitignore Dockerfile install.sh LICENSE README.md requirements.txt

VOLUME /sycgram/data

ENTRYPOINT ["/usr/local/bin/python3", "-u", "main.py"]
