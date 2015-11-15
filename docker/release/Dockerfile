FROM pluralsight/todobackend-base:latest
MAINTAINER Justin Menga <justin.menga@gmail.com>

ADD target /wheelhouse

RUN . /appenv/bin/activate && \
    pip install --no-index -f wheelhouse todobackend && \
    rm -rf /wheelhouse

EXPOSE 8000
