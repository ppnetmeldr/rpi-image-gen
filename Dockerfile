# syntax=docker/dockerfile:1.6
FROM debian:bookworm

ENV DEBIAN_FRONTEND=noninteractive
ARG TARGETARCH

# ------------------------------------------------------------
# Base dependencies
# ------------------------------------------------------------
RUN apt-get update && apt-get install --no-install-recommends -y \
    build-essential \
    curl \
    git \
    ca-certificates \
    sudo \
    gpg \
    gpg-agent \
  && rm -rf /var/lib/apt/lists/*

# ------------------------------------------------------------
# Raspberry Pi archive key
# ------------------------------------------------------------
RUN curl -fsSL https://archive.raspberrypi.com/debian/raspberrypi.gpg.key \
  | gpg --dearmor \
  > /usr/share/keyrings/raspberrypi-archive-keyring.gpg

# ------------------------------------------------------------
# Copy CURRENT directory (Dockerfile is already here)
# ------------------------------------------------------------
WORKDIR /work/rpi-image-gen
COPY . .

# Ensure scripts are executable
RUN chmod +x \
    install_deps.sh

# ------------------------------------------------------------
# Architecture-specific dependencies
# ------------------------------------------------------------
RUN /bin/bash -euxc '\
  ARCH="${TARGETARCH:-$(dpkg --print-architecture)}"; \
  case "${ARCH}" in \
    arm64) \
      echo "Building for arm64"; \
      apt-get update; \
      ./install_deps.sh; \
      ;; \
    amd64) \
      echo "Building for amd64 (override binfmt check)"; \
      sed -i "s|\"\${binfmt_misc_required}\" == \"1\"|! -z \"\"|g" \
        scripts/dependencies_check; \
      if ! grep -q binfmt_misc /proc/filesystems; then \
        echo "binfmt_misc not supported on host"; exit 1; \
      fi; \
      apt-get update; \
      apt-get install --no-install-recommends -y \
        qemu-user-static \
        dirmngr \
        slirp4netns \
        quilt \
        parted \
        debootstrap \
        zerofree \
        libcap2-bin \
        libarchive-tools \
        xxd \
        file \
        kmod \
        bc \
        pigz \
        arch-test; \
      ./install_deps.sh; \
      ;; \
    *) \
      echo "Unsupported architecture: ${ARCH}"; exit 1 ;; \
  esac && rm -rf /var/lib/apt/lists/*'

# ------------------------------------------------------------
# Create non-root user
# ------------------------------------------------------------
ENV USER=imagegen
ENV UID=4000

RUN useradd -u ${UID} -m -s /bin/bash ${USER} \
  && echo "${USER}:${USER}" | chpasswd \
  && echo "${USER} ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/${USER} \
  && chmod 0440 /etc/sudoers.d/${USER}

# ------------------------------------------------------------
# Switch to non-root
# ------------------------------------------------------------
USER ${USER}
WORKDIR /home/${USER}

CMD ["/bin/bash"]
