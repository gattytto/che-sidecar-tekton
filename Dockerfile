 
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
RUN cd src && git clone https://github.com/tektoncd/experimental && cd experimental/octant-plugin && \
    go build -o $GOPATH/src/tekton-plugin ./ 

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
    dnf install -y wget which nodejs dnf-plugins-core java-11-openjdk.x86_64 && \
    dnf copr enable -y chmouel/tektoncd-cli && \
    dnf install -y tektoncd-cli && mkdir -p /home/theia/.octant/plugins && \
    wget https://github.com/vmware-tanzu/octant/releases/download/v0.10.2/octant_0.10.2_Linux-64bit.tar.gz && \
    tar -zxvf octant_0.10.2_Linux-64bit.tar.gz && cd octant_0.10.2_Linux-64bit && cp octant /usr/local/bin/
    
ADD etc/entrypoint.sh /entrypoint.sh
RUN mkdir -p /home/theia/.octant/plugins
COPY --from=builder /go/src/tekton-plugin /home/theia/.octant/plugins/
RUN chgrp -R 0 /home/theia/.octant && chmod -R g+rwX /home/theia/.octant
RUN chown -R 1724:root /home/theia/.octant
ENTRYPOINT [ "/entrypoint.sh" ]
CMD ${PLUGIN_REMOTE_ENDPOINT_EXECUTABLE}
