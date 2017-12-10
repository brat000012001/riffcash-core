FROM riffcashcompiler AS COMPILER
ENV MAKEJOBS -j4
ENV RUN_TESTS false
ENV CHECK_DOC 0
ENV BOOST_TEST_RANDOM 1
ENV CCACHE_SIZE 100M
ENV CCACHE_TEMPDIR /tmp/.ccache-temp
ENV CCACHE_COMPRESS 1
ENV SDK_URL https://bitcoincore.org/depends-sources/sdks
ENV PYTHON_DEBUG 1
ENV WINEDEBUG fixme-all
ENV RIFFCASH_SCRYPT 0
ENV HOST x86_64-unknown-linux-gnu
ENV DEP_OPTS "NO_QT=1 NO_UPNP=1 DEBUG=1 ALLOW_HOST_PACKAGES=1"
ENV PACKAGES "cmake imagemagick libcap-dev librsvg2-bin libz-dev libbz2-dev libtiff-tools python-dev"
ENV BITCOIN_CONFIG "--enable-gui --enable-reduce-exports --enable-sse2"
ENV OSX_SDK 10.11
ENV GOAL install
COPY . /source/
WORKDIR /source/
RUN ./autogen.sh
RUN mkdir /source/build
RUN make $MAKEJOBS -C depends HOST=$HOST
RUN depends/$HOST/native/bin/ccache --max-size=$CCACHE_SIZE
RUN cd /source/build && ../configure \
                    --cache-file=config.cache \
                    --disable-dependency-tracking \
                    --prefix=/opt/riffcash \
                    --bindir=/opt/riffcash/bin \
                    --libdir=/opt/riffcash/lib \
                    --enable-gui \
                    --enable-sse2 \
                    --enable-zmq \
                    --enable-glibc-back-compat \
                    --enable-reduce-exports \
                    --with-incompatible-bdb \
                    --disable-tests \
                    CPPFLAGS=-DDEBUG_LOCKORDER

RUN cd /source/build && make $MAKEJOBS distdir VERSION=$HOST
RUN cd /source/build/riffcash-$HOST && ./configure \
                    --cache-file=config.cache \
                    --disable-dependency-tracking \
                    --prefix=/opt/riffcash \
                    --bindir=/opt/riffcash/bin \
                    --libdir=/opt/riffcash/lib \
                    --enable-gui \
                    --enable-sse2 \
                    --enable-zmq \
                    --enable-glibc-back-compat \
                    --enable-reduce-exports \
                    --with-incompatible-bdb \
                    --disable-tests \
                    CPPFLAGS=-DDEBUG_LOCKORDER

RUN cd /source/build/riffcash-$HOST && make $MAKEJOBS $GOAL

FROM debian:stretch-slim
#COPY --from=COMPILER /lib/x86_64-linux-gnu/ /lib/x86_64-linux-gnu/
COPY --from=COMPILER /usr/lib/x86_64-linux-gnu/libboost_system.so.1.62.0 /usr/lib/x86_64-linux-gnu/
COPY --from=COMPILER /usr/lib/x86_64-linux-gnu/libboost_filesystem.so.1.62.0 /usr/lib/x86_64-linux-gnu/
COPY --from=COMPILER /usr/lib/x86_64-linux-gnu/libboost_program_options.so.1.62.0 /usr/lib/x86_64-linux-gnu/
COPY --from=COMPILER /usr/lib/x86_64-linux-gnu/libboost_thread.so.1.62.0 /usr/lib/x86_64-linux-gnu/
COPY --from=COMPILER /usr/lib/x86_64-linux-gnu/libboost_chrono.so.1.62.0 /usr/lib/x86_64-linux-gnu/
COPY --from=COMPILER /usr/lib/x86_64-linux-gnu/libdb_cxx-5.3.so /usr/lib/x86_64-linux-gnu/
COPY --from=COMPILER /usr/lib/x86_64-linux-gnu/libssl.so.1.1 /usr/lib/x86_64-linux-gnu/
COPY --from=COMPILER /usr/lib/x86_64-linux-gnu/libcrypto.so.1.1 /usr/lib/x86_64-linux-gnu/
COPY --from=COMPILER /usr/lib/x86_64-linux-gnu/libevent_pthreads-2.0.so.5 /usr/lib/x86_64-linux-gnu/
COPY --from=COMPILER /usr/lib/x86_64-linux-gnu/libevent-2.0.so.5 /usr/lib/x86_64-linux-gnu/
COPY --from=COMPILER /lib/x86_64-linux-gnu/librt.so.1 /lib/x86_64-linux-gnu/
COPY --from=COMPILER /usr/lib/x86_64-linux-gnu/libstdc++.so.6 /usr/lib/x86_64-linux-gnu/
COPY --from=COMPILER /lib/x86_64-linux-gnu/libm.so.6 /lib/x86_64-linux-gnu/
COPY --from=COMPILER /lib/x86_64-linux-gnu/libgcc_s.so.1 /lib/x86_64-linux-gnu/
COPY --from=COMPILER /lib/x86_64-linux-gnu/libpthread.so.0 /lib/x86_64-linux-gnu/
COPY --from=COMPILER /lib/x86_64-linux-gnu/libc.so.6 /lib/x86_64-linux-gnu/
COPY --from=COMPILER /lib/x86_64-linux-gnu/libdl.so.2 /lib/x86_64-linux-gnu/
COPY --from=COMPILER /usr/lib/x86_64-linux-gnu/libevent_core-2.0.so.5 /usr/lib/x86_64-linux-gnu/
COPY --from=COMPILER /opt/riffcash /opt/riffcash

EXPOSE 19765/tcp 19910/tcp 19756/tcp

ENTRYPOINT ["/opt/riffcash/bin/riffcashd"]
