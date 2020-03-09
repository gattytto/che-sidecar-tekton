 
# Copyright (c) 2019 Red Hat, Inc.
# This program and the accompanying materials are made
# available under the terms of the Eclipse Public License 2.0
# which is available at https://www.eclipse.org/legal/epl-2.0/
#
# SPDX-License-Identifier: EPL-2.0
#
# Contributors:
#   Red Hat, Inc. - initial API and implementation
FROM golang:alpine AS builder
RUN apk update && apk add --no-cache git
WORKDIR $GOPATH
RUN mkdir src && cd src && git clone https://github.com/tektoncd/experimental && cd experimental/octant-plugin && \
    go build -o /usr/local/bin/tekton-plugin ./
COPY /usr/local/bin/tekton-plugin .
FROM quay.io/buildah/stable:v1.11.3

ENV KUBECTL_VERSION v1.17.0
ENV HELM_VERSION v3.0.2
ENV HOME=/home/theia

ADD etc/storage.conf $HOME/.config/containers/storage.conf

RUN mkdir /projects && \
    # Change permissions to let any arbitrary user
    for f in "${HOME}" "/etc/passwd" "/projects"; do \
      echo "Changing permissions on ${f}" && chgrp -R 0 ${f} && \
      chmod -R g+rwX ${f}; \
    done && \
    # buildah login requires writing to /run
    chgrp -R 0 /run && chmod -R g+rwX /run && \
    curl https://storage.googleapis.com/kubernetes-release/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl -o /usr/local/bin/kubectl && \
    chmod +x /usr/local/bin/kubectl && \
    curl -o- -L https://get.helm.sh/helm-${HELM_VERSION}-linux-amd64.tar.gz | tar xvz -C /usr/local/bin --strip 1 && \
    # 'which' utility is used by VS Code Kubernetes extension to find the binaries, e.g. 'kubectl'
    dnf install -y which nodejs dnf-plugins-core java-11-openjdk.x86_64 && \
    dnf copr enable -y chmouel/tektoncd-cli && \
    dnf install -y tektoncd-cli
ADD ./tekton-plugin /usr/local/bin/
ADD etc/entrypoint.sh /entrypoint.sh

ENTRYPOINT [ "/entrypoint.sh" ]
CMD ${PLUGIN_REMOTE_ENDPOINT_EXECUTABLE}
