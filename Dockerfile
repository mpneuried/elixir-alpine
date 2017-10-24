FROM alpine:3.6
MAINTAINER mpneuried

# versiosn to install
ENV ELIXIR_V 1.5.2
ENV OTP_VERSION="20.1.2"

# install erlang
RUN set -xe \
	&& OTP_DOWNLOAD_URL="https://github.com/erlang/otp/archive/OTP-${OTP_VERSION}.tar.gz" \
	&& OTP_DOWNLOAD_SHA256="f3d370015c3544503cb76cfaf0bfc8de0f35d89eee206db9f1b9603cbffd8907" \
	&& apk add --no-cache --virtual .fetch-deps \
		curl \
		ca-certificates \
	&& curl -fSL -o otp-src.tar.gz "$OTP_DOWNLOAD_URL" \
	&& echo "$OTP_DOWNLOAD_SHA256  otp-src.tar.gz" | sha256sum -c - \
	&& apk add --no-cache --virtual .build-deps \
		gcc \
		libc-dev \
		make \
		autoconf \
		ncurses-dev \
		openssl-dev \
		tar \
	&& export ERL_TOP="/usr/src/otp_src_${OTP_VERSION%%@*}" \
	&& mkdir -vp $ERL_TOP \
	&& tar -xzf otp-src.tar.gz -C $ERL_TOP --strip-components=1 \
	&& rm otp-src.tar.gz \
	&& ( cd $ERL_TOP \
	  && ./otp_build autoconf \
	  && ./configure \
	  && make -j$(getconf _NPROCESSORS_ONLN) \
	  && make install ) \
	&& rm -rf $ERL_TOP \
	&& find /usr/local -regex '/usr/local/lib/erlang/\(lib/\|erts-\).*/\(man\|doc\|src\|obj\|c_src\|emacs\|info\|examples\)' | xargs rm -rf \
	&& rm -rf \
		/usr/local/lib/erlang/erts*/lib/lib*.a \
		/usr/local/lib/erlang/usr/lib/lib*.a \
		/usr/local/lib/erlang/lib/*/lib/lib*.a \
	&& scanelf --nobanner -E ET_EXEC -BF '%F' --recursive /usr/local | xargs strip --strip-all \
	&& scanelf --nobanner -E ET_DYN -BF '%F' --recursive /usr/local | xargs -r strip --strip-unneeded \
	&& runDeps=$( \
		scanelf --needed --nobanner --recursive /usr/local \
			| awk '{ gsub(/,/, "\nso:", $2); print "so:" $2 }' \
			| sort -u \
			| xargs -r apk info --installed \
			| sort -u \
	) \
	&& apk add --virtual .erlang-rundeps $runDeps \
	&& apk del .fetch-deps .build-deps

# install elixir
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

# show versions
RUN erl -eval 'erlang:display(erlang:system_info(otp_release)), halt().'  -noshell
RUN elixir -v

RUN mix local.hex --force
RUN mix local.rebar --force
