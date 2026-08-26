FROM ruby:3.4-slim AS builder

WORKDIR /usr/src/app

RUN apt-get update && \
    apt-get install -y --no-install-recommends build-essential && \
    rm -rf /var/lib/apt/lists/*

COPY Gemfile Gemfile.lock ./
RUN bundle config set frozen true && \
    bundle config set without 'development test' && \
    bundle install

FROM ruby:3.4-slim

WORKDIR /usr/src/app

COPY --from=builder /usr/local/bundle /usr/local/bundle
COPY inalambribot.rb ./

CMD ["./inalambribot.rb"]
