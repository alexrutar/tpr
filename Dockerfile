FROM alpine:latest

MAINTAINER Alex Rutar (https://rutar.org)

# install fish
RUN apk update && \
    apk add --no-cache fish && \
    rm -f /tmp/* /etc/apk/cache/*

RUN apk add --no-cache curl

RUN sed -i -e "s/bin\/ash/usr\/bin\/fish/" /etc/passwd

ENV SHELL /usr/bin/fish

# install fisher
RUN ["curl", "-sL", "https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish", "-o", "fisher_install.fish"]
RUN /usr/bin/fish -c "source fisher_install.fish && fisher install jorgebucaran/fisher"

# # install tpr locally
COPY . /script
RUN /usr/bin/fish -c "fisher install /script"
