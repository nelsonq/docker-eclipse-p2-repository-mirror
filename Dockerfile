# Provides eclipse p2 repository mirroring service powered by nginx with specific eclipse p2 repository

ARG FROM_IMAGE_OF_ECLIPSE_APPLICATION
ARG MIRROR_SOURCE_NAME
ARG MIRROR_ROOT_PATH=/root/eclipse-mirror
ARG MIRROR_DESTINATION_PATH=$MIRROR_ROOT_PATH/$MIRROR_SOURCE_NAME
ARG MIRROR_CONTEXT=eclipse-mirror
FROM $FROM_IMAGE_OF_ECLIPSE_APPLICATION as eclipse-application

ARG MIRROR_ROOT_PATH
ARG MIRROR_SOURCE_URL
ARG MIRROR_DESTINATION_PATH

RUN test -n $MIRROR_SOURCE_URL
RUN test -n $MIRROR_SOURCE_NAME
RUN test -n $MIRROR_ROOT_PATH
RUN test -n $MIRROR_DESTINATION_PATH

RUN echo "The mirror source url is $MIRROR_SOURCE_URL"
RUN echo "The mirror source name is $MIRROR_SOURCE_NAME"
RUN echo "The mirror root path is $MIRROR_ROOT_PATH"
RUN echo "The mirror destination path is $MIRROR_DESTINATION_PATH"

RUN mkdir -p $MIRROR_DESTINATION_PATH

# mirroring eclipse p2 metadata
RUN /opt/eclipse/eclipse -nosplash -verbose \
    -application org.eclipse.equinox.p2.metadata.repository.mirrorApplication \
    -source $MIRROR_SOURCE_URL \
    -destination file:$MIRROR_DESTINATION_PATH

# mirroring eclipse p2 artifacts
RUN /opt/eclipse/eclipse -nosplash -verbose \
    -application org.eclipse.equinox.p2.artifact.repository.mirrorApplication \
    -source $MIRROR_SOURCE_URL \
    -destination file:$MIRROR_DESTINATION_PATH

FROM nginx:1.21.3 
ARG MIRROR_DESTINATION_PATH
ARG MIRROR_SOURCE_NAME
ARG MIRROR_CONTEXT

RUN test -n $MIRROR_DESTINATION_PATH
RUN test -n $MIRROR_SOURCE_NAME
RUN test -n $MIRROR_CONTEXT

RUN echo $MIRROR_DESTINATION_PATH
RUN echo $MIRROR_SOURCE_NAME
RUN echo $MIRROR_CONTEXT

ENV SOURCE_MIRROR_DESTINATION_PATH=$MIRROR_DESTINATION_PATH
ENV TARGET_MIRROR_DESTINATION_PATH=/usr/share/nginx/html/$MIRROR_CONTEXT/$MIRROR_SOURCE_NAME
RUN mkdir -p $TARGET_MIRROR_DESTINATION_PATH 

# Deploy the downloaded eclipse p2 metadata and artifacts from last stage to a static content folder for public access
COPY --from=eclipse-application $SOURCE_MIRROR_DESTINATION_PATH $TARGET_MIRROR_DESTINATION_PATH 
