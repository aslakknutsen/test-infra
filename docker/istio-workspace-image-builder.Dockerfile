FROM quay.io/maistra-dev/istio-workspace-builder-base:latest

ADD scripts/istio-workspace-image-build.sh /usr/local/bin/build-images.sh
RUN chmod +x /usr/local/bin/build-images.sh
