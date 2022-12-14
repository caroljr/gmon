FROM ruby:2.7.5
RUN apt-get update \
	&& apt-get install -y --no-install-recommends \
		make \
		g++-multilib \
	&& rm -rf /var/lib/apt/lists/*
RUN gem install puma sinatra puma-metrics pg
RUN gem install bundler:1.17.3
ENV APP_HOME /app
RUN mkdir $APP_HOME
WORKDIR $APP_HOME
ADD Gemfile* $APP_HOME/
RUN bundle install
ADD . $APP_HOME
RUN /bin/bash -c 'export LANG=pt_BR.UTF-8'
RUN /bin/bash -c 'unlink /etc/localtime'
RUN /bin/bash -c 'ln -s /usr/share/zoneinfo/America/Sao_Paulo /etc/localtime'
CMD ["puma", "config.ru", "-C", "puma/config.rb"]