from debian

RUN apt-get update -y && \
	apt-get install -y --no-install-recommends \ 
		 build-essential wget unzip perl curl \
		 libpcre3 libpcre3-dev libpcrecpp0 libssl-dev zlib1g-dev \
		 procps libreadline-dev libncurses5-dev \
	&& rm -rf /var/lib/apt/lists/*

ENV NPS_VERSION 1.9.32.6
ENV NGINX_VERSION 1.9.4
ENV OPENRESTY_VERSION 1.9.3.1
ENV OPENRESTY_PREFIX /opt/openresty
ENV NGINX_PREFIX /opt/openresty/nginx
ENV VAR_PREFIX /var/nginx

WORKDIR /tmp
RUN wget http://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz && \
        wget --no-check-certificate https://github.com/pagespeed/ngx_pagespeed/archive/release-${NPS_VERSION}-beta.zip && \
	wget --no-check-certificate https://github.com/yaoweibin/ngx_http_substitutions_filter_module/archive/v0.6.4.tar.gz && \
	unzip release-${NPS_VERSION}-beta.zip && \
	cd ngx_pagespeed-release-${NPS_VERSION}-beta/ && \
	wget --no-check-certificate https://dl.google.com/dl/page-speed/psol/${NPS_VERSION}.tar.gz && \
	tar -xzvf ${NPS_VERSION}.tar.gz && \
	cd .. && \
	tar xzf v0.6.4.tar.gz && \
	tar xzf nginx-${NGINX_VERSION}.tar.gz && \
	cd nginx-${NGINX_VERSION} && \
	./configure --prefix=/opt/packages/nginx --add-module=../ngx_http_substitutions_filter_module-0.6.4 \
		--add-module=../ngx_pagespeed-release-${NPS_VERSION}-beta  && \
	make && make install

RUN cd /root \
 && echo "==> Downloading OpenResty..." \
 && curl -sSL http://openresty.org/download/ngx_openresty-${OPENRESTY_VERSION}.tar.gz | tar -xvz \
 && echo "==> Configuring OpenResty..." \
 && cd ngx_openresty-* \
 && readonly NPROC=$(grep -c ^processor /proc/cpuinfo 2>/dev/null || 1) \
 && echo "using upto $NPROC threads" \
 && ./configure \
    --prefix=$OPENRESTY_PREFIX \
    --http-client-body-temp-path=$VAR_PREFIX/client_body_temp \
    --http-proxy-temp-path=$VAR_PREFIX/proxy_temp \
    --http-log-path=$VAR_PREFIX/access.log \
    --error-log-path=$VAR_PREFIX/error.log \
    --pid-path=$VAR_PREFIX/nginx.pid \
    --lock-path=$VAR_PREFIX/nginx.lock \
    --with-luajit \
    --with-pcre-jit \
    --with-ipv6 \
    --with-http_ssl_module \
    --without-http_ssi_module \
    --without-http_userid_module \
    --without-http_uwsgi_module \
    --without-http_scgi_module \
    --add-module=/tmp/ngx_http_substitutions_filter_module-0.6.4 \
    --add-module=/tmp/ngx_pagespeed-release-${NPS_VERSION}-beta \
    -j${NPROC} \
 && echo "==> Building OpenResty..." \
 && make -j${NPROC} \
 && echo "==> Installing OpenResty..." \
 && make install \
 && echo "==> Finishing..." \
 && ln -sf $NGINX_PREFIX/sbin/nginx /usr/local/bin/nginx \
 && ln -sf $NGINX_PREFIX/sbin/nginx /usr/local/bin/openresty \
 && ln -sf $OPENRESTY_PREFIX/bin/resty /usr/local/bin/resty \
 && ln -sf $OPENRESTY_PREFIX/luajit/bin/luajit-* $OPENRESTY_PREFIX/luajit/bin/lua \
 && ln -sf $OPENRESTY_PREFIX/luajit/bin/luajit-* /usr/local/bin/lua \
 && rm -rf /root/ngx_openresty* \
 && rm -rf /tmp/*

WORKDIR $NGINX_PREFIX/

ONBUILD RUN rm -rf conf/* html/*
ONBUILD COPY nginx $NGINX_PREFIX/
