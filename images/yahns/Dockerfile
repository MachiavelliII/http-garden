FROM http-garden-soil:latest

RUN apt -y update \
 && apt -y upgrade \
 && apt -y install --no-install-recommends ruby-dev ragel \
 && gem install raindrops kgio olddoc rack sleepy_penguin kcar

ARG PARSER_REPO
RUN git clone --recurse-submodules "$PARSER_REPO"

ARG PARSER_VERSION
ARG PARSER_BRANCH
RUN cd /app/unicorn \
 && git pull origin "$PARSER_BRANCH" \
 && git checkout "$PARSER_VERSION" \
 && export LC_ALL=C.UTF-8 \
 && make "-j$(nproc)" install-gem

ARG APP_REPO
RUN git clone --recurse-submodules "$APP_REPO"

ARG APP_VERSION
ARG APP_BRANCH
RUN cd /app/yahns \
 && git pull origin "$APP_BRANCH" \
 && git checkout "$APP_VERSION" \
 && make install-gem

COPY yahns.conf .

ARG CONFIG_FILE
COPY $CONFIG_FILE ./config.ru
ARG BACKEND
RUN sed -i "s/PROXY_BACKEND_PLACEHOLDER/$BACKEND/g" config.ru

CMD ["yahns", "-c", "yahns.conf"]
