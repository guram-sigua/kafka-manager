FROM amazonlinux:2 as builder
LABEL "org.opencontainers.image.authors"="guram-sigua"
RUN yum update -y
RUN yum install -y curl java-1.8.0-openjdk java-1.8.0-openjdk-devel
RUN curl -sL https://rpm.nodesource.com/setup_10.x | bash -
RUN yum install nodejs -y
RUN curl https://bintray.com/sbt/rpm/rpm | tee /etc/yum.repos.d/bintray-sbt-rpm.repo && \
    yum install -y sbt git
RUN cd /opt && git clone https://github.com/yahoo/kafka-manager.git 
RUN cd /opt/kafka-manager && echo 'scalacOptions ++= Seq("-Xmax-classfile-name", "200")' >> build.sbt && sbt clean dist
RUN yum install -y rpm-build
RUN cd /opt/kafka-manager && \
    sbt rpm:packageBin

FROM amazonlinux:2
LABEL "org.opencontainers.image.authors"="levkov"
EXPOSE 9001 9000
COPY --from=builder /opt/kafka-manager/target/rpm/RPMS/noarch/kafka-manager-*.noarch.rpm /tmp/

RUN rm -f /etc/localtime && ln -sf /usr/share/zoneinfo/UTC /etc/localtime && \
    yum update -y && \
    yum install -y python-pip \
                   shadow-utils \
                   systemd \
                   java-1.8.0-openjdk && \
    pip install supervisor requests==2.5.3

COPY conf/application.conf /etc/kafka-manager/application.conf
COPY conf/supervisord.conf /etc/supervisord.conf
CMD ["/usr/bin/supervisord"]

