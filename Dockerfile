# The base image is the latest 4.x node (LTS) on jessie (debian)
# -onbuild will install the node dependencies found in the project package.json
# and copy its content in /usr/src/app, its WORKDIR
FROM node:5.12

# My favourite workaround
RUN cd $(npm root -g)/npm \
 && npm install fs-extra \
 && sed -i -e s/graceful-fs/fs-extra/ -e s/fs\.rename/fs\.move/ ./lib/utils/rename.js

# Install ffmpeg on the system
WORKDIR /tmp
RUN wget http://ffmpeg.gusari.org/static/64bit/ffmpeg.static.64bit.latest.tar.gz
RUN tar -xzf ffmpeg.static.64bit.latest.tar.gz
RUN mv ffmpeg ffprobe /usr/local/bin

# Install some deps
RUN apt-get update \
 && apt-get install -y libcairo2-dev libjpeg-dev libpango1.0-dev libgif-dev build-essential g++ libgeoip-dev software-properties-common

# Get latest gcc and g++
# RUN echo "deb http://ftp.debian.org/debian/ stretch main" >> /etc/apt/sources.list
# RUN apt-get update
# RUN apt-get install -y gcc-5 g++-5
# 
# # Use latest gcc and g++
# RUN update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-5 80 --slave /usr/bin/g++ g++ /usr/bin/g++-5
# RUN update-alternatives --set gcc /usr/bin/gcc-5

# Run npm install
WORKDIR /usr/src/app
COPY . /usr/src/app
RUN npm install

# Download a country lookup database
RUN wget http://geolite.maxmind.com/download/geoip/database/GeoLiteCity.dat.gz && gunzip GeoLiteCity.dat.gz

# Restore the changes to the captcha module which were overwritten by npm install
RUN git checkout node_modules/captcha/captcha.js

# Get ircd.js modified for livechan
WORKDIR /usr/src
RUN git clone https://github.com/emgram769/ircd.js
WORKDIR /usr/src/ircd.js
RUN npm install
WORKDIR /usr/src/app

# Make sure the public/tmp/uploads and public/tmp/thumb folders are writable
RUN mkdir public/tmp/uploads public/tmp/thumb
RUN chmod 777 public/tmp/uploads public/tmp/thumb

# Set admin password
RUN printf "ass\nass\n" | node lib/set-password.js

# Start the damn thing!
CMD npm start

# Expose da sheed
EXPOSE 5080
