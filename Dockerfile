FROM tercen/dartrusttidy:travis-17

# get bowtie2 binaries and add them to the PATH
RUN wget https://github.com/BenLangmead/bowtie2/releases/download/v2.4.2/bowtie2-2.4.2-linux-x86_64.zip && \
    unzip bowtie2-2.4.2-linux-x86_64.zip && \
    rm bowtie2-2.4.2-linux-x86_64.zip
ENV PATH="/bowtie2-2.4.2-linux-x86_64/:${PATH}"

# get cmake (required to install trinity)
RUN wget https://github.com/Kitware/CMake/releases/download/v3.20.1/cmake-3.20.1-linux-x86_64.tar.gz && \
    tar xzvf cmake-3.20.1-linux-x86_64.tar.gz && \
    rm cmake-3.20.1-linux-x86_64.tar.gz
ENV PATH="/cmake-3.20.1-linux-x86_64/bin:${PATH}"


# get Trinity, install it
RUN apt-get update && \
    apt install -y libbz2-dev

RUN apt-get update && \
    apt install -y liblzma-dev

RUN wget https://github.com/trinityrnaseq/trinityrnaseq/releases/download/v2.12.0/trinityrnaseq-v2.12.0.FULL.tar.gz && \
    tar xzvf trinityrnaseq-v2.12.0.FULL.tar.gz && \
    rm trinityrnaseq-v2.12.0.FULL.tar.gz
WORKDIR /trinityrnaseq-v2.12.0
RUN make
ENV PATH="/trinityrnaseq-v2.12.0:${PATH}"
WORKDIR /

# get IgBlast
RUN wget https://ftp.ncbi.nih.gov/blast/executables/igblast/release/LATEST/ncbi-igblast-1.17.1-x64-linux.tar.gz && \
    tar xzvf ncbi-igblast-1.17.1-x64-linux.tar.gz && \
    rm ncbi-igblast-1.17.1-x64-linux.tar.gz
ENV PATH="/ncbi-igblast-1.17.1/bin:${PATH}"
WORKDIR /ncbi-igblast-1.17.1/bin
ENV IGDATA=/ncbi-igblast-1.17.1/bin
RUN cp -r /ncbi-igblast-1.17.1/internal_data /ncbi-igblast-1.17.1/bin/
RUN cp -r /ncbi-igblast-1.17.1/optional_file /ncbi-igblast-1.17.1/bin/
WORKDIR /

# Get Salmon binaries and add them to the PATH
RUN wget https://github.com/COMBINE-lab/salmon/releases/download/v1.4.0/salmon-1.4.0_linux_x86_64.tar.gz && \
    tar xzvf salmon-1.4.0_linux_x86_64.tar.gz && \
    rm salmon-1.4.0_linux_x86_64.tar.gz
ENV PATH="/salmon-latest_linux_x86_64/bin:${PATH}"

# install python and required packages
RUN apt-get update
RUN apt install -y python3-pip
RUN pip3 install numpy
RUN pip3 install biopython
RUN update-alternatives --install /usr/bin/python python /usr/bin/python3 1

# install samtools
RUN apt install -y samtools

# install jellyfish
RUN wget https://github.com/gmarcais/Jellyfish/releases/download/v2.3.0/jellyfish-2.3.0.tar.gz && \
    tar xzvf jellyfish-2.3.0.tar.gz && \
    rm jellyfish-2.3.0.tar.gz
WORKDIR jellyfish-2.3.0
RUN ./configure
RUN make
RUN make install
RUN ldconfig
WORKDIR /

# install java
RUN apt install -y default-jre

# download transcriptomes
RUN wget https://github.com/pachterlab/kallisto-transcriptome-indices/releases/download/ensembl-96/mus_musculus.tar.gz && \
    tar xzvf mus_musculus.tar.gz && \
    rm mus_musculus.tar.gz
RUN wget https://github.com/pachterlab/kallisto-transcriptome-indices/releases/download/ensembl-96/homo_sapiens.tar.gz && \
    tar xzvf homo_sapiens.tar.gz && \
    rm homo_sapiens.tar.gz

# install kallisto
RUN wget https://github.com/pachterlab/kallisto/releases/download/v0.46.1/kallisto_linux-v0.46.1.tar.gz && \
    tar xzvf kallisto_linux-v0.46.1.tar.gz && \
    rm kallisto_linux-v0.46.1.tar.gz
ENV PATH="/kallisto/:${PATH}"

# install graphviz
RUN apt install -y graphviz

#  Finally, download tracer
RUN git clone http://www.github.com/teichlab/tracer
RUN chmod u+x tracer/tracer
WORKDIR /tracer
RUN pip3 install -r requirements.txt
WORKDIR /

# copy our configuration file into the image
COPY tercen_tracer.conf /

COPY collect_TRA_TRB_in_fasta.py /

USER root
WORKDIR /operator

RUN git clone https://github.com/tercen/TraCeR_operator

WORKDIR /operator/TraCeR_operator

RUN echo "PATH=${PATH}" >> /usr/local/lib/R/etc/Renviron

RUN echo "08/03/2022 21:55" && git pull
RUN echo "08/03/2022 21:55" && git checkout

RUN R -e "install.packages('renv')"
RUN R -e "renv::consent(provided=TRUE);renv::restore(confirm=FALSE)"

ENTRYPOINT [ "R","--no-save","--no-restore","--no-environ","--slave","-f","main.R", "--args"]
CMD [ "--taskId", "someid", "--serviceUri", "https://tercen.com", "--token", "sometoken"]
