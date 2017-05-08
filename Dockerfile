FROM node:6

## set HEXO_SERVER_PORT environment default
ENV HEXO_SERVER_PORT=4000

RUN apt-get update
RUN npm install -g hexo-cli
