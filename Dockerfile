FROM tercen/tracer_docker_operator_base:1.0.2-base

COPY collect_TRA_TRB_in_fasta.py /

USER root

COPY . /operator
WORKDIR /operator

ENV RENV_VERSION 0.13.0
RUN R -e "install.packages('remotes', repos = c(CRAN = 'https://cran.r-project.org'))"
RUN R -e "remotes::install_github('rstudio/renv@${RENV_VERSION}')"

RUN R -e "renv::consent(provided=TRUE);renv::restore(confirm=FALSE)"

ENTRYPOINT [ "R","--no-save","--no-restore","--no-environ","--slave","-f","main.R", "--args"]
CMD [ "--taskId", "someid", "--serviceUri", "https://tercen.com", "--token", "sometoken"]
