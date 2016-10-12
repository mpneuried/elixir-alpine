FROM alpine:3.4
MAINTAINER mpneuried

# install erlang
RUN apk --update add erlang

# install elixir
ENV ELIXIR_V 1.3.4

RUN apk --update add --virtual build-dependencies wget ca-certificates && \
	wget https://github.com/elixir-lang/elixir/releases/download/v${ELIXIR_V}/Precompiled.zip && \
	mkdir -p /opt/elixir-${ELIXIR_V}/ && \
	unzip Precompiled.zip -d /opt/elixir-${ELIXIR_V}/ && \
	rm Precompiled.zip && \
	apk del build-dependencies && \
	rm -rf /etc/ssl

# cleanup
RUN rm -rf /var/cache/apk/*

ENV PATH $PATH:/opt/elixir-${ELIXIR_V}/bin