FROM rocker/geospatial:latest

RUN R -e 'devtools::install_github("trestletech/plumber")'

EXPOSE 8000

ENTRYPOINT ["R", "-e", "pr <- plumber::plumb(rev(commandArgs())[1]); pr$run(host='0.0.0.0', port=8000, swagger=TRUE)"]

WORKDIR /root

CMD ["/usr/local/lib/R/site-library/plumber/examples/04-mean-sum/plumber.R"]

