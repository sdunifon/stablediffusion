FROM ubuntu as sd
ENV CUDA_HOME=/usr/local/cuda-11.4
ENV MAIN_WORKDIR=/workspace/sd
ENV MODELS_DIR=/workspace/models


RUN apt-get update
RUN export DEBIAN_FRONTEND=noninteractive \
    && apt-get -y install git curl build-essential wget python3 python3-pip
    
RUN echo "alias python=python3" > ~/.profile
SHELL ["/bin/bash", "-lc"]

# RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y 


# RUN cargo install fd-find ripgrep

WORKDIR ${MAIN_WORKDIR}

COPY requirements.txt .
COPY setup.py .

RUN python3 -m pip install -r requirements.txt


RUN conda install pytorch==1.12.1 torchvision==0.13.1 -c pytorch
RUN pip install transformers==4.19.2 diffusers invisible-watermark
RUN pip install -e .

#xformers
RUN conda install -c nvidia/label/cuda-11.4.0 cuda-nvcc
RUN conda install -c conda-forge gcc
RUN conda install -c conda-forge gxx_linux-64==9.5.0

WORKDIR ${MODELS_DIR}
COPY --from=models /workspace/models .

WORKDIR ${MAIN_WORKDIR}

CMD "/bin/bash"

FROM sd as xformers
WORKDIR /workspace/xformers
RUN mkdir  /xformers
RUN git clone https://github.com/facebookresearch/xformers.git /xformers
WORKDIR /xformers

RUN git submodule update --init --recursive
RUN pip install -r requirements.txt
RUN pip install -e .




FROM ubuntu as models
RUN export DEBIAN_FRONTEND=noninteractive \
    && apt-get -y install wget
WORKDIR ${MODELS_DIR}
RUN wget https://huggingface.co/stabilityai/stable-diffusion-2-1/blob/main/v2-1_768-ema-pruned.ckpt
RUN wget https://huggingface.co/stabilityai/stable-diffusion-2-1-base/resolve/main/v2-1_512-ema-pruned.ckpt
