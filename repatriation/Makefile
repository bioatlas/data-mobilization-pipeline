#! make

PWD := $(shell pwd)

all: init repatriate

init:
	@echo "Please create your .Renviron file with your GBIF credentials in this dir fist"
	@echo "(see Renviron-sample for an example of how it should look)"

mirroreum-shell:
	 docker run --rm -it \
		-v $(PWD):/home/rstudio \
		-v $(PWD)/.Renviron:/root/.Renviron \
		-w /home/rstudio \
		bioatlas/mirroreum:0.9.1 bash

repatriate:
	 docker run --rm -it \
		-v $(PWD):/home/rstudio \
		-v $(PWD)/.Renviron:/root/.Renviron \
		-w /home/rstudio \
		bioatlas/mirroreum:0.9.1 ./repatriate.R
