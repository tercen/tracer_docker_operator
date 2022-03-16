FROM tercen/runtime-r40:4.0.4-1

# get bowtie2 binaries and add them to the PATH
RUN wget -q https://github.com/BenLangmead/bowtie2/releases/download/v2.4.2/bowtie2-2.4.2-linux-x86_64.zip && \
    unzip bowtie2-2.4.2-linux-x86_64.zip && \
    rm bowtie2-2.4.2-linux-x86_64.zip

ENV PATH="/bowtie2-2.4.2-linux-x86_64/:${PATH}"

# get cmake (required to install trinity)
RUN wget -q https://github.com/Kitware/CMake/releases/download/v3.20.1/cmake-3.20.1-linux-x86_64.tar.gz && \
    tar xzf cmake-3.20.1-linux-x86_64.tar.gz && \
    rm cmake-3.20.1-linux-x86_64.tar.gz

ENV PATH="/cmake-3.20.1-linux-x86_64/bin:${PATH}"


# get Trinity, install it
RUN apt install -y libbz2-dev liblzma-dev && \
    wget -q https://github.com/trinityrnaseq/trinityrnaseq/releases/download/v2.12.0/trinityrnaseq-v2.12.0.FULL.tar.gz && \
    tar xzf trinityrnaseq-v2.12.0.FULL.tar.gz && \
    rm trinityrnaseq-v2.12.0.FULL.tar.gz

WORKDIR /trinityrnaseq-v2.12.0
RUN make
ENV PATH="/trinityrnaseq-v2.12.0:${PATH}"
WORKDIR /

# get IgBlast
RUN wget -q https://ftp.ncbi.nih.gov/blast/executables/igblast/release/1.17.1/ncbi-igblast-1.17.1-x64-linux.tar.gz && \
    tar xzf ncbi-igblast-1.17.1-x64-linux.tar.gz && \
    rm ncbi-igblast-1.17.1-x64-linux.tar.gz

ENV PATH="/ncbi-igblast-1.17.1/bin:${PATH}"
WORKDIR /ncbi-igblast-1.17.1/bin
ENV IGDATA=/ncbi-igblast-1.17.1/bin

RUN cp -r /ncbi-igblast-1.17.1/internal_data /ncbi-igblast-1.17.1/bin/ && \
    cp -r /ncbi-igblast-1.17.1/optional_file /ncbi-igblast-1.17.1/bin/

WORKDIR /

# Get Salmon binaries and add them to the PATH
RUN wget https://github.com/COMBINE-lab/salmon/releases/download/v1.4.0/salmon-1.4.0_linux_x86_64.tar.gz && \
    tar xzvf salmon-1.4.0_linux_x86_64.tar.gz && \
    rm salmon-1.4.0_linux_x86_64.tar.gz

ENV PATH="/salmon-latest_linux_x86_64/bin:${PATH}"

# install python and required packages
RUN apt install -y python3-pip && \
    pip3 install numpy && \
    pip3 install biopython && \
    update-alternatives --install /usr/bin/python python /usr/bin/python3 1 && \
    apt install -y samtools

# install jellyfish
RUN wget -q https://github.com/gmarcais/Jellyfish/releases/download/v2.3.0/jellyfish-2.3.0.tar.gz && \
    tar xzf jellyfish-2.3.0.tar.gz && \
    rm jellyfish-2.3.0.tar.gz

WORKDIR jellyfish-2.3.0

RUN ./configure && \
    make && \
    make install && \
    ldconfig

WORKDIR /

# install java
RUN apt install -y default-jre

# download transcriptomes
RUN wget -q https://github.com/pachterlab/kallisto-transcriptome-indices/releases/download/ensembl-96/mus_musculus.tar.gz && \
    tar xzf mus_musculus.tar.gz && \
    rm mus_musculus.tar.gz && \
    wget -q https://github.com/pachterlab/kallisto-transcriptome-indices/releases/download/ensembl-96/homo_sapiens.tar.gz && \
    tar xzf homo_sapiens.tar.gz && \
    rm homo_sapiens.tar.gz && \
    wget -q https://github.com/pachterlab/kallisto/releases/download/v0.46.1/kallisto_linux-v0.46.1.tar.gz && \
    tar xzf kallisto_linux-v0.46.1.tar.gz && \
    rm kallisto_linux-v0.46.1.tar.gz

ENV PATH="/kallisto/:${PATH}"

# install graphviz
RUN apt install -y graphviz && \
    git clone http://www.github.com/teichlab/tracer && \
    chmod u+x tracer/tracer

WORKDIR /tracer

RUN pip3 install -r requirements.txt

WORKDIR /

# copy our configuration file into the image
COPY tercen_tracer.conf /

COPY collect_TRA_TRB_in_fasta.py /

COPY . /operator
WORKDIR /operator

USER root
WORKDIR /operator

RUN echo "PATH=${PATH}" >> /usr/local/lib/R/etc/Renviron

#RUN R -e "renv::init(bare = TRUE)"
#RUN R -e "renv::install('askpass')"
#RUN R -e "renv::hydrate()"

ENV RENV_VERSION 0.13.0
RUN R -e "install.packages('remotes', repos = c(CRAN = 'https://cran.r-project.org'))"
RUN R -e "remotes::install_github('rstudio/renv@${RENV_VERSION}')"

RUN R -e "renv::consent(provided=TRUE);renv::restore(confirm=FALSE)"

ENTRYPOINT [ "R","--no-save","--no-restore","--no-environ","--slave","-f","main.R", "--args"]
CMD [ "--taskId", "someid", "--serviceUri", "https://tercen.com", "--token", "sometoken"]
