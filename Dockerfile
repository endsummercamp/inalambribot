FROM ruby:3.3

WORKDIR /usr/src/app

RUN gem install telegram-bot-ruby

COPY . .

CMD ["./inalambribot.rb"]
