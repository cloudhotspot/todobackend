FROM cloudhotspot/todobackend-base:latest
MAINTAINER Justin Menga <justin.menga@gmail.com>
LABEL application="todobackend"

# Expose port 8000
EXPOSE 8000

# Mount point for application artifacts
COPY target /wheelhouse

# Install application artifacts
RUN . /appenv/bin/activate && \
    pip install --no-index -f /wheelhouse todobackend[aws] && \
    rm -rf /wheelhouse
