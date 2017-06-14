# 从debian:jessie镜像基础上安装nginx
FROM debian:jessie
# 声明此Dockerfile维护者的邮箱
MAINTAINER NGINX Docker Maintainers "octerye@126.com"
# 定义软件版本及编译工具变量
ENV TZ=Asia/Shanghai
ENV NGINX_VERSION 1.12.0
ENV OPENSSL_VERSION 1.1.0f
ENV ZLIB_VERSION 1.2.11
ENV PCRE_VERSION 8.40
ENV CONCAT_VERSION 1.2.2
ENV BUILD_TOOLS wget gcc make g++ patch build-essential libtool
ENV SRC_DIR /opt/nginx

# 切换到工作目录
WORKDIR ${SRC_DIR}

# 开始编译nginx，我们这里使用编译安装nginx而不是使用官方提供的nginx镜像是因为这里使用到了第三方的concat模块和健康检测模块，只能编译了。
# 把所有的安装命令都写在一个RUN指令中是因为这样可以减小镜像层数，缩减镜像大小。推荐使用反斜杠和&&把所有的安装命令放置到一行中。
RUN apt-get update \
    && apt-get -y --no-install-recommends install ca-certificates ${BUILD_TOOLS} \
    && wget http://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz  \
    && wget https://www.openssl.org/source/openssl-${OPENSSL_VERSION}.tar.gz  \
    && wget http://www.zlib.net/zlib-${ZLIB_VERSION}.tar.gz  \
    && wget https://ftp.pcre.org/pub/pcre/pcre-${PCRE_VERSION}.tar.gz  \
    && wget https://github.com/alibaba/nginx-http-concat/archive/${CONCAT_VERSION}.tar.gz -O nginx-http-concat-${CONCAT_VERSION}.tar.gz  \
    && wget https://github.com/yaoweibin/nginx_upstream_check_module/archive/master.tar.gz -O nginx_upstream_check_module-master.tar.gz  \
    && tar xf nginx-${NGINX_VERSION}.tar.gz  \
    && tar xf openssl-${OPENSSL_VERSION}.tar.gz  \
    && tar xf zlib-${ZLIB_VERSION}.tar.gz  \
    && tar xf pcre-${PCRE_VERSION}.tar.gz  \
    && tar xf nginx-http-concat-${CONCAT_VERSION}.tar.gz  \
    && tar xf nginx_upstream_check_module-master.tar.gz  \
    && cd nginx-${NGINX_VERSION}  \
    && patch -p0 < ../nginx_upstream_check_module-master/check_1.11.5+.patch \
    && ./configure --prefix=/usr/local/nginx --with-pcre=../pcre-${PCRE_VERSION} \
                --with-zlib=../zlib-${ZLIB_VERSION} \
                --with-http_ssl_module \
                --with-openssl=../openssl-${OPENSSL_VERSION} \
                --add-module=../nginx-http-concat-${CONCAT_VERSION}  \
                --add-module=../nginx_upstream_check_module-master \
    && make -j$(nproc) \
    && make install \
    && rm -rf ${SRC_DIR} \
    && apt-get purge -y --auto-remove ${BUILD_TOOLS} \
    && rm -rf /var/lib/apt/lists/* \
    && ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone \

EXPOSE 80 443
STOPSIGNAL SIGQUIT
CMD ["/usr/local/nginx/sbin/nginx", "-g", "daemon off;"]