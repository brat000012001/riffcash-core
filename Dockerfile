FROM riffcashcompiler AS COMPILER
ADD . /source/
WORKDIR /source/
RUN ./autogen.sh
RUN cd /source/build && ../configure \
                    --cache-file=config.cache \
                    --disable-dependency-tracking \
                    --prefix=/opt/riffcash \
                    --bindir=/opt/riffcash/bin \
                    --libdir=/opt/riffcash/lib \
                    --enable-zmq \
                    --enable-glibc-back-compat \
                    --enable-reduce-exports \
                    --with-incompatible-bdb \
                    --disable-tests \
                    CPPFLAGS=-DDEBUG_LOCKORDER

RUN cd /source/build && make -j4 distdir VERSION=x86_64-unknown-linux-gnu
RUN cd /source/build/riffcash-x86_64-unknown-linux-gnu && ./configure \
                    --cache-file=config.cache \
                    --disable-dependency-tracking \
                    --prefix=/opt/riffcash \
                    --bindir=/opt/riffcash/bin \
                    --libdir=/opt/riffcash/lib \
                    --enable-zmq \
                    --enable-glibc-back-compat \
                    --enable-reduce-exports \
                    --with-incompatible-bdb \
                    --disable-tests \
                    CPPFLAGS=-DDEBUG_LOCKORDER

RUN cd /source/build/riffcash-x86_64-unknown-linux-gnu && make -j4 install
FROM riffcashrunner

COPY --from=COMPILER /opt/riffcash /opt/riffcash

ENTRYPOINT ["/opt/riffcash/bin/riffcashd"]
