FROM ruby:2.7
RUN apt-get update \
&& apt-get install -y python3-pip \
&& apt-get install -y libopencv-dev 
RUN git clone https://github.com/misasa/image_mosaic.git
RUN pip3 install -r /image_mosaic/requirements.txt \
&& pip3 install /image_mosaic
RUN gem install bundler
WORKDIR /usr/src/app
COPY . .
RUN bundle install
RUN rm -r pkg | bundle exec rake build multi_stage.gemspec
RUN gem install pkg/multi_stage-*.gem
#ARG UID=1001
#ARG GID=1001

#RUN addgroup -gid ${GID} medusa && useradd -m --shell /bin/sh --gid ${GID} --uid ${UID} medusa 
#USER medusa
#WORKDIR /home/medusa
#CMD ["/bin/bash"]
