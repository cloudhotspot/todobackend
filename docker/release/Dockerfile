FROM cloudhotspot/todobackend-base:latest
MAINTAINER Justin Menga <justin.menga@gmail.com>
LABEL application="todobackend"

# Expose port 8000
EXPOSE 8000

# Mount point for application artefacts
COPY target /wheelhouse

# Install application artefacts
RUN . /appenv/bin/activate && \
    pip install --no-index -f wheelhouse todobackend && \
    rm -rf /wheelhouse
