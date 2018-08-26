
FROM ubuntu:xenial

# Python 3.6

ENV LC_ALL C.UTF-8
ENV LANG C.UTF-8

RUN apt-get update && apt-get install -y \
  htop \
  git \
  make \
  vim \
  curl \
  wget \
  tmux \
  build-essential \
  libssl-dev \
  zlib1g-dev \
  libbz2-dev \
  libsqlite3-dev \
  libreadline-dev \
  libxslt1-dev \
  libffi-dev \
  libxml2-dev \
  redis-tools

ARG PYENV_ROOT=/opt/pyenv
RUN git clone https://github.com/pyenv/pyenv.git $PYENV_ROOT
ENV PATH $PYENV_ROOT/shims:$PYENV_ROOT/bin:$PATH
RUN pyenv install 3.6.5
RUN pyenv global 3.6.5
RUN pip install --upgrade pip

# Java

RUN apt-get update && apt-get install -y openjdk-8-jdk
RUN update-ca-certificates -f
ENV JAVA_HOME /usr/lib/jvm/java-8-openjdk-amd64

# Spark

ARG SPARK_VERSION=2.3.0
ARG SPARK_DIRNAME=spark-${SPARK_VERSION}
ARG SPARK_PACKAGE=${SPARK_DIRNAME}-bin-hadoop2.7
ARG SPARK_MIRROR=http://apache.cs.utah.edu/spark
ARG SPARK_URL=${SPARK_MIRROR}/${SPARK_DIRNAME}/${SPARK_PACKAGE}.tgz
ENV SPARK_HOME=/opt/${SPARK_DIRNAME}

ENV PATH $PATH:${SPARK_HOME}/bin

RUN curl -sL --retry 3 \
  $SPARK_URL \
  | gunzip \
  | tar x -C /opt/ \
 && mv /opt/$SPARK_PACKAGE $SPARK_HOME \
 && chown -R root:root $SPARK_HOME

COPY spark-env.sh $SPARK_HOME/conf
COPY spark-defaults.conf $SPARK_HOME/conf
