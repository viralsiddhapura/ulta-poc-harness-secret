FROM harness/delegate:latest

USER root

# Install Terraform (with architecture detection for ARM64/AMD64)
RUN apt-get update && apt-get install -y wget unzip curl git && \
    ARCH=$(dpkg --print-architecture) && \
    wget https://releases.hashicorp.com/terraform/1.6.0/terraform_1.6.0_linux_${ARCH}.zip && \
    unzip terraform_1.6.0_linux_${ARCH}.zip && \
    mv terraform /usr/local/bin/ && \
    rm terraform_1.6.0_linux_${ARCH}.zip && \
    terraform --version

# Install Miniconda with Python 3.11 (works on ARM64)
RUN ARCH=$(dpkg --print-architecture) && \
    if [ "$ARCH" = "arm64" ]; then CONDA_ARCH="aarch64"; else CONDA_ARCH="x86_64"; fi && \
    curl -LO https://repo.anaconda.com/miniconda/Miniconda3-py311_24.1.2-0-Linux-${CONDA_ARCH}.sh && \
    bash Miniconda3-py311_24.1.2-0-Linux-${CONDA_ARCH}.sh -b -p /opt/miniconda && \
    rm Miniconda3-py311_24.1.2-0-Linux-${CONDA_ARCH}.sh && \
    /opt/miniconda/bin/python --version

# Install Google Cloud CLI
ENV CLOUDSDK_PYTHON=/opt/miniconda/bin/python
ENV PATH="/opt/miniconda/bin:$PATH"
RUN ARCH=$(dpkg --print-architecture) && \
    if [ "$ARCH" = "arm64" ]; then GCLOUD_ARCH="arm"; else GCLOUD_ARCH="x86_64"; fi && \
    curl -O https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-cli-linux-${GCLOUD_ARCH}.tar.gz && \
    tar -xzf google-cloud-cli-linux-${GCLOUD_ARCH}.tar.gz && \
    mv google-cloud-sdk /opt/ && \
    ln -s /opt/google-cloud-sdk/bin/gcloud /usr/local/bin/gcloud && \
    ln -s /opt/google-cloud-sdk/bin/gsutil /usr/local/bin/gsutil && \
    rm google-cloud-cli-linux-${GCLOUD_ARCH}.tar.gz && \
    gcloud --version

# Note: Keeping root user as delegate scripts need write permissions
# The delegate runs in a container with limited capabilities anyway
