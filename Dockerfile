# Copyright (c) 2019 Red Hat, Inc.
# This program and the accompanying materials are made
# available under the terms of the Eclipse Public License 2.0
# which is available at https://www.eclipse.org/legal/epl-2.0/
#
# SPDX-License-Identifier: EPL-2.0
#
# Contributors:
#   Red Hat, Inc. - initial API and implementation

FROM debian:10-slim

ENV HOME=/home/theia
ENV KUBECTL_VERSION v1.16.1
ENV HELM_VERSION v2.14.3

RUN apt-get update && \
    apt-get install git wget gnupg unzip curl software-properties-common dirmngr apt-transport-https lsb-release ca-certificates -y && \
    echo 'deb http://apt.llvm.org/buster/ llvm-toolchain-buster-8 main' >> /etc/apt/sources.list && \
    wget -O - https://apt.llvm.org/llvm-snapshot.gpg.key | apt-key add - && \
    wget -O - https://deb.nodesource.com/setup_10.x | bash - && \
    apt-get update && \
    apt-get install nodejs clangd-8 clang-8 clang-format-8 gdb autoconf gcc g++ libc6 make bison libxml2-dev -y && \
    apt-get clean && apt-get -y autoremove && rm -rf /var/lib/apt/lists/* && \
    update-alternatives --install /usr/bin/clang clang /usr/bin/clang-8 100 && \
    update-alternatives --install /usr/bin/clang++ clang++ /usr/bin/clang++-8 100 && \
    update-alternatives --install /usr/bin/clangd clangd /usr/bin/clangd-8 100 && \
    update-alternatives --install /usr/bin/clang-format clang-format /usr/bin/clang-format-8 100 && \
    mkdir -p /usr/share/man/man1/ && mkdir -p /usr/share/man/man7/

# Install bazel (https://docs.bazel.build/versions/master/install-ubuntu.html)
RUN wget -qO - https://adoptopenjdk.jfrog.io/adoptopenjdk/api/gpg/key/public | apt-key add - && \
    curl https://bazel.build/bazel-release.pub.gpg | apt-key add - && \
    apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 3EFE0E0A2F2F60AA && \
    echo "deb http://ppa.launchpad.net/tektoncd/cli/ubuntu eoan main" | tee /etc/apt/sources.list.d/tektoncd-ubuntu-cli.list && \
    echo "deb [arch=amd64] http://storage.googleapis.com/bazel-apt stable jdk1.8" | tee /etc/apt/sources.list.d/bazel.list && \
    add-apt-repository --yes https://adoptopenjdk.jfrog.io/adoptopenjdk/deb/ && \
    apt-get update && \
    apt-get -y install adoptopenjdk-8-hotspot tektoncd-cli && \
    apt-get -y install bazel && \
    apt-get -y upgrade bazel 

RUN curl https://storage.googleapis.com/kubernetes-release/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl -o /usr/local/bin/kubectl && \
    chmod +x /usr/local/bin/kubectl && \
    curl -o- -L https://storage.googleapis.com/kubernetes-helm/helm-${HELM_VERSION}-linux-amd64.tar.gz | tar xvz -C /usr/local/bin --strip 1 && \
    # set up local Helm configuration skipping Tiller installation
    helm init --client-only
    
RUN cd /tmp && wget https://github.com/bazelbuild/buildtools/releases/download/0.29.0/buildifier && chmod 777 buildifier && mv buildifier /usr/bin/
RUN cd /tmp && wget https://github.com/bazelbuild/buildtools/releases/download/0.29.0/buildozer && chmod 777 buildozer && mv buildozer /usr/bin/

RUN mkdir /projects
    for f in "${HOME}" "/etc/passwd" "/projects"; do \
      echo "Changing permissions on ${f}" && chgrp -R 0 ${f} && \
      chmod -R g+rwX ${f}; \
    done

ADD etc/entrypoint.sh /entrypoint.sh

ENTRYPOINT [ "/entrypoint.sh" ]
CMD ${PLUGIN_REMOTE_ENDPOINT_EXECUTABLE}
