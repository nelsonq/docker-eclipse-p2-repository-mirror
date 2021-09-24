# Provides eclipse p2 repository mirroring service powered by nginx with specific eclipse p2 repository

ARG ECLIPSE_IMAGE

ARG CONTEXT_PATH=eclipse

# The path of mirror content. e.g. rt/rap/3.5, releases/photon
ARG CONTENT_PATH

# Local mirror path for publish
ARG LOCAL_MIRROR_PATH=/usr/share/nginx/html/$CONTEXT_PATH/$CONTENT_PATH

########
#  build mirror
########

FROM $ECLIPSE_IMAGE as eclipse

ARG LOCAL_MIRROR_PATH
ARG REMOTE_MIRROR_URL
ARG SKIP

RUN test -n $REMOTE_MIRROR_URL

RUN mkdir -p $LOCAL_MIRROR_PATH

SHELL ["/bin/bash", "-c"]

# mirroring eclipse p2 metadata
RUN if [[ "$SKIP" != "true" ]] ; then \ 
    /opt/eclipse/eclipse -nosplash -verbose \
    -application org.eclipse.equinox.p2.metadata.repository.mirrorApplication \
    -source $REMOTE_MIRROR_URL \
    -destination file:$LOCAL_MIRROR_PATH ; \
    fi

# mirroring eclipse p2 artifacts
RUN if [[ "$SKIP" != "true" ]] ; then \
    /opt/eclipse/eclipse -nosplash -verbose \
    -application org.eclipse.equinox.p2.artifact.repository.mirrorApplication \
    -source $REMOTE_MIRROR_URL \
    -destination file:$LOCAL_MIRROR_PATH ; \
    fi

########
#  deploy mirror
########

FROM nginx:1.21.3 

ARG LOCAL_MIRROR_PATH

RUN mkdir -p $LOCAL_MIRROR_PATH

# Deploy the downloaded eclipse p2 metadata and artifacts from last stage to a static content folder for public access
COPY --from=eclipse $LOCAL_MIRROR_PATH $LOCAL_MIRROR_PATH
