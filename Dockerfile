FROM alpine:3.14

LABEL maintainer="Harry - The DevOps Guy <HarryTheDevOpsGuy@gmail.com>" \
    python-version=3.8

ENV USERNAME="harry"
ENV USERGROUP="harry"

USER root
WORKDIR /root

# Fetch the latest apk manifests
# Update existing packages
# Install bash and vim
# Cleanup after ourselves to keep this layer as small as possible
# Details: https://wiki.alpinelinux.org/wiki/Alpine_Linux_package_management
RUN apk update \
    && apk upgrade \
    && apk add --no-cache bash vim sudo jq curl net-tools aws-cli ansible

# Add a group named "${USERGROUP}"
#   -g, Assign this ID to the new group
# Details: https://busybox.net/BusyBox.html#addgroup
RUN addgroup -g 1000 ${USERGROUP}

#
# Add 'root' to the '${USERGROUP}' group
#
RUN addgroup root ${USERGROUP}

# Add a user named "${USERNAME}"
#   -D, Do not assign a password
#   -u, Assign this ID to the new user
#   -s, Set this shell as the user's default login shell
#   -h, Set this home path as the user's home path
#   -G, Add the new user to an existing group
# Details: https://busybox.net/BusyBox.html#adduser
RUN adduser -D -u 1000 -s /bin/bash -h /home/${USERNAME} -G ${USERGROUP} ${USERNAME}

# Alpine Linux default shell for root is '/bin/ash'
# Change this to '/bin/bash' so that  '/etc/bashrc'
# can be loaded when entering the running container
RUN sed -i 's,/bin/ash,/bin/bash,g' /etc/passwd

# Add the '${USERGROUP}' group to the sudoers file
# No password required
RUN echo "%${USERGROUP} ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

# Add our custom welcome message script to profile.d.
# This is automatically sourced by /etc/profile when
# switching users.
COPY scripts/etc/profile.d/welcome.sh /etc/profile.d/welcome.sh

COPY scripts/etc/bashrc /etc/bashrc

COPY scripts/usr/share/entrypoint.sh /usr/share/entrypoint.sh

# Must set this value for the bash shell to source
# the '/etc/bashrc' file.
# See: https://stackoverflow.com/q/29021704
ENV BASH_ENV /etc/bashrc

# Use this path to save runtime variables persisted
# across user sessions.
RUN mkdir -p /usr/share/entrypoint \
    && chown ${USERNAME}:${USERGROUP} /usr/share/entrypoint

RUN apk add  --no-cache util-linux busybox-extras terraform openssh
RUN rm -rf /var/cache/apk/*
EXPOSE 22

# This is the last necessary piece for loading the
# '/etc/bashrc' file. The 'exec' syntax
ENTRYPOINT [ "/usr/share/entrypoint.sh" ]
#USER ${USERNAME}
#WORKDIR /home/${USERNAME}

CMD ["/usr/sbin/sshd","-D"]
