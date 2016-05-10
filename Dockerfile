FROM ruby:2.3.1-alpine

MAINTAINER Russell Trow <russell@dockleafdigital.com>

ENV BUILD_PACKAGES nodejs

RUN apk update && \
    apk upgrade && \
    apk add $BUILD_PACKAGES && \
    rm -rf /var/cache/apk/*

RUN mkdir /app
WORKDIR /app
COPY main.rb /app