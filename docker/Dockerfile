
ARG BASE_IMAGE=ubuntu:bionic

FROM ${BASE_IMAGE}

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
  parallel \
  software-properties-common \
  build-essential \
  libssl-dev \
  zlib1g-dev \
  libbz2-dev \
  libsqlite3-dev \
  libreadline-dev \
  libxslt1-dev \
  libffi-dev \
  libxml2-dev \
  liblzma-dev

# Python 3
ARG PYTHON_VERSION=3.8.3
ARG PYENV_ROOT=/root/.pyenv
RUN curl https://pyenv.run | bash
ENV PATH $PYENV_ROOT/bin:$PYENV_ROOT/shims:$PATH
RUN pyenv install $PYTHON_VERSION
RUN pyenv global $PYTHON_VERSION
RUN pip install --upgrade pip

# Java
RUN apt-get update && apt-get install -y openjdk-8-jdk
RUN update-ca-certificates -f
ENV JAVA_HOME /usr/lib/jvm/java-8-openjdk-amd64

# Spark
ARG SPARK_URL=http://apache.cs.utah.edu/spark/spark-3.0.2/spark-3.0.2-bin-hadoop3.2.tgz
ENV SPARK_HOME=/opt/spark
ENV PATH $PATH:${SPARK_HOME}/bin

RUN curl -sL --retry 3 $SPARK_URL | gunzip | tar x -C /opt/ \
  && mv /opt/spark-* $SPARK_HOME \
  && chown -R root:root $SPARK_HOME

COPY spark-env.sh $SPARK_HOME/conf
COPY spark-defaults.conf $SPARK_HOME/conf
