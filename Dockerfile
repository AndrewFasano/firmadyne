FROM ubuntu:20.04
# run with --privileged -v /dev:/dev

# Install apt dependencies
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get upgrade -y && apt-get install -y \
    automake \
    autotools-dev \
    bridge-utils \
    build-essential \
    busybox-static \
    curl \
    dmsetup \
    dnsmasq \
    fakeroot \
    git \
    iputils-ping \
    kmod \
    kpartx \
    libpq-dev \
    libsqlite3-0 \
    netcat-openbsd \
    nmap \
    python3-pip \
    python3-psycopg2 \
    qemu-system-arm \
    qemu-system-mips \
    qemu-system-x86 \
    qemu-utils \
    snmp \
    socat \
    sqlite3 \
    sudo \
    tmux \
    uml-utilities \
    unzip \
    util-linux \
    vim \
    vlan \
    wget

# Not entirely duplicates
RUN apt-get install -y busybox-static fakeroot git dmsetup kpartx netcat-openbsd nmap python3-psycopg2 snmp uml-utilities util-linux vlan postgresql wget qemu-system-arm qemu-system-mips qemu-system-x86 qemu-utils vim unzip

# Install binwalk + dependencies - XXX: We use a fork to fix a bug in deps.sh for ubuntu 20.04
RUN git clone -q --depth=1 https://github.com/AndrewFasano/binwalk.git /root/binwalk

RUN update-alternatives --install /usr/bin/python python /usr/bin/python3 10
RUN cd /root/binwalk && \
    bash -ex ./deps.sh --yes

RUN cd /root/binwalk && \
    python3 ./setup.py install

RUN pip3 install git+https://github.com/ahupp/python-magic && \
    pip3 install git+https://github.com/sviehb/jefferson && \
    pip3 install pylzma # jefferson dependency, needs build-essential

# Download binaries
RUN mkdir -p /firmadyne/binaries && \
    wget --quiet -N --continue -P/firmadyne/binaries/ https://github.com/firmadyne/kernel-v2.6/releases/download/v1.1/vmlinux.mipsel && \
    wget --quiet -N --continue -P/firmadyne/binaries/ https://github.com/firmadyne/kernel-v2.6/releases/download/v1.1/vmlinux.mipseb && \
    wget --quiet -N --continue -P/firmadyne/binaries/ https://github.com/firmadyne/kernel-v4.1/releases/download/v1.1/zImage.armel && \
    wget --quiet -N --continue -P/firmadyne/binaries/ https://github.com/firmadyne/console/releases/download/v1.0/console.armel && \
    wget --quiet -N --continue -P/firmadyne/binaries/ https://github.com/firmadyne/console/releases/download/v1.0/console.mipseb && \
    wget --quiet -N --continue -P/firmadyne/binaries/ https://github.com/firmadyne/console/releases/download/v1.0/console.mipsel && \
    wget --quiet -N --continue -P/firmadyne/binaries/ https://github.com/firmadyne/libnvram/releases/download/v1.0c/libnvram.so.armel && \
    wget --quiet -N --continue -P/firmadyne/binaries/ https://github.com/firmadyne/libnvram/releases/download/v1.0c/libnvram.so.mipseb && \
    wget --quiet -N --continue -P/firmadyne/binaries/ https://github.com/firmadyne/libnvram/releases/download/v1.0c/libnvram.so.mipsel

# Create firmadyne user
#RUN useradd -m firmadyne
#RUN echo "firmadyne:firmadyne" | chpasswd && adduser firmadyne sudo

COPY database/ /firmadyne/firmadyne/database/

COPY sources/ /firmadyne/firmadyne/sources/
COPY scripts/ /firmadyne/firmadyne/scripts/
COPY example_analysis.sh /firmadyne/firmadyne/
COPY firmadyne.config /firmadyne/

# Run setup script
ADD setup.sh /tmp/setup.sh
RUN /tmp/setup.sh
ADD startup.sh /firmadyne/startup.sh

# TMP HACK
RUN mv /firmadyne/binaries /firmadyne/firmadyne/

#USER firmadyne
USER root
ENTRYPOINT ["/firmadyne/startup.sh"]
CMD ["/bin/bash"]
