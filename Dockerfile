
FROM ubuntu as sd
ENV CUDA_HOME=/usr/local/cuda-11.4
ENV MAIN_WORKDIR=/workspace/sd
ENV MODELS_DIR=/workspace/models
ENV XFORMERS_DIR=/workspace/xformers
ARG USERNAME=sd
ARG USER_UID=1000
ARG USER_GID=$USER_UID
ENV CONDA_DIR=/home/${USERNAME}/.conda
ENV PATH=/home/${USERNAME}/.local/bin:$CONDA_DIR/bin:$PATH

USER root
RUN apt-get update
RUN export DEBIAN_FRONTEND=noninteractive \
    && apt-get -y install git curl build-essential wget python3 python3-pip
    
RUN echo "alias python=python3" > ~/.profile
SHELL ["/bin/bash", "-lc"]



# Put conda in j so we can use conda activate



# Create the user and give sudo powers
RUN groupadd --gid $USER_GID $USERNAME \
    && useradd --uid $USER_UID --gid $USER_GID -m $USERNAME \
    #
    # [Optional] Add sudo support. Omit if you don't need to install software after connecting.
    && apt-get update \
    && apt-get install -y sudo \
    && echo $USERNAME ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/$USERNAME \
    && chmod 0440 /etc/sudoers.d/$USERNAME


RUN mkdir -p ${MAIN_WORKDIR}; chown -R ${USERNAME} ${MAIN_WORKDIR}
USER $USERNAME
WORKDIR ${MAIN_WORKDIR}

RUN wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-aarch64.sh -O ~/miniconda.sh && \
    /bin/bash ~/miniconda.sh -b -p ${CONDA_DIR}

RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y 
RUN cargo install fd-find ripgrep


COPY --chown=${USERNAME}:${USERNAME} requirements.txt setup.py ./

RUN python3 -m pip install -r requirements.txt


RUN conda install pytorch==1.12.1 torchvision==0.13.1 -c pytorch
RUN pip install transformers==4.19.2 diffusers invisible-watermark
RUN pip install -e .

#xformer
RUN conda install -c nvidia/label/cuda-11.4.0 cuda-nvcc
RUN conda install -c conda-forge gcc
RUN conda install -c conda-forge gxx_linux-64==9.5.0


WORKDIR ${MODELS_DIR}
USER root
RUN chown -R ${USERNAME} ${MODELS_DIR}
USER ${USERNAME}
RUN wget https://huggingface.co/stabilityai/stable-diffusion-2-1/blob/main/v2-1_768-ema-pruned.ckpt
RUN wget https://huggingface.co/stabilityai/stable-diffusion-2-1-base/resolve/main/v2-1_512-ema-pruned.ckpt


WORKDIR ${MAIN_WORKDIR}

CMD "/bin/bash"

WORKDIR ${XFORMERS_DIR}
USER root
RUN chown -R ${USERNAME} ${XFORMERS_DIR}
USER ${USERNAME}
WORKDIR /workspace/xformers
RUN git clone https://github.com/facebookresearch/xformers.git /workspace/xformers
RUN git submodule update --init --recursive
RUN pip install -r requirements.txt
RUN pip install -e .

