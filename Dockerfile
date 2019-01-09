FROM dyne/devuan:beowulf
LABEL maintainer="Denis Roio <jaromil@dyne.org>" \
	  homepage="https://github.com/samaaron/sonic-pi/"

ENV SRC=/app/sonic-pi

RUN echo "deb-src http://deb.devuan.org/merged ascii main" >> /etc/apt/sources.list
RUN mkdir -p /usr/share/man/man1/ \
&& apt-get update \
&& apt-get upgrade -y -q \
&& apt-get install -y -q --allow-downgrades --no-install-recommends \
   lsb-release make autoconf automake libtool cmake zsh \
   g++ ruby ruby-dev pkg-config git build-essential libjack-jackd2-dev libsndfile1-dev libasound2-dev libavahi-client-dev libicu-dev libreadline6-dev libfftw3-dev libxt-dev libudev-dev cmake libboost-dev libqwt-qt5-dev libqt5scintilla2-dev libqt5svg5-dev qt5-qmake qt5-default qttools5-dev qttools5-dev-tools qtdeclarative5-dev libqt5webkit5-dev qtpositioning5-dev libqt5sensors5-dev qtmultimedia5-dev libffi-dev curl python erlang-base \
   supercollider sc3-plugins libaubio-dev \
   ruby supercollider sc3-plugins \
   libsamplerate0-dev libavfilter-dev libavformat-dev libavutil-dev

WORKDIR /app
# COPY . /app/sonic-pi
RUN git clone https://github.com/samaaron/sonic-pi \
	&& cd sonic-pi && git submodule update --init --recursive

# install aubio from source
RUN git clone https://git.aubio.org/git/aubio && cd aubio \
	&& make getwaf && ./waf configure && ./waf build && ./waf install

# install osmid from source
RUN git clone https://github.com/llloret/osmid.git \
	&& mkdir -p osmid/build && cd osmid/build \
	&& cmake .. && make && mkdir -p $SRC/app/server/native/linux/osmid \
	&& install m2o o2m -t $SRC/app/server/native/linux/osmid

# compile erlang server
RUN cd $SRC/app/server/erlang \
	&& erlc osc.erl && erlc pi_server.erl	

RUN apt-get install -y -q libqt5opengl5-dev libssl-dev
# GUI only deps: libboost-dev libqwt-qt5-dev libqt5scintilla2-dev libqt5svg5-dev qt5-qmake qt5-default qttools5-dev qttools5-dev-tools qtdeclarative5-dev libqt5webkit5-dev qtpositioning5-dev libqt5sensors5-dev qtmultimedia5-dev

# fix installation of ruby rugged
RUN gem install rugged \
	&& cp -a /var/lib/gems/2.5.0/gems/rugged-0.27.7/. $SRC/app/server/ruby/vendor/rugged \
	&& sed -i 's/rugged-0.26.0/rugged/' $SRC/app/server/ruby/bin/compile-extensions.rb

# comple gui
RUN cd $SRC/app/gui/qt \
	&& ruby ../../server/ruby/bin/compile-extensions.rb \
	&& ruby ../../server/ruby/bin/i18n-tool.rb -t \
	&& cp -f ruby_help.tmpl ruby_help.h \
	&& ruby ../../server/ruby/bin/qt-doc.rb -o ruby_help.h \
	&& lrelease SonicPi.pro && qmake -qt=qt5 SonicPi.pro && make


CMD /bin/bash
