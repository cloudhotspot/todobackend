FROM cloudhotspot/todobackend-base:latest
MAINTAINER Justin Menga <justin.menga@gmail.com>
LABEL application="todobackend"

RUN sed -i "s/http:\/\/archive./http:\/\/nz.archive./g" /etc/apt/sources.list

# Mount point for application artifacts
COPY target /wheelhouse

# Entrypoint script
COPY scripts/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# Install application artifacts
RUN . /appenv/bin/activate && \
    pip install --no-index -f /wheelhouse todobackend && \
    rm -rf /wheelhouse
