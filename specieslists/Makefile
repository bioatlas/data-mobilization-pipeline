#! make

PWD := $(shell pwd)

init: Animalia_fridlysta.csv blacklist.csv graylist.csv moss_lav_svamp_fridlysta.csv

all: init protected-species specieslists redlisted-species

mirroreum-shell:
	 docker run --rm -it -v $(PWD):/home/rstudio \
		-w /home/rstudio \
		bioatlas/mirroreum:0.9.1 bash

protected-species:
	 docker run --rm -it -v $(PWD):/home/rstudio \
		-w /home/rstudio \
		bioatlas/mirroreum:0.9.1 ./protected.R

specieslists:
	 docker run --rm -it -v $(PWD):/home/rstudio \
		-w /home/rstudio \
		bioatlas/mirroreum:0.9.1 ./specieslists.R

redlisted-species: redlist redlist-extra

redlist:
	@echo "Do you have a redlist-rc.sh w env vars for ADB (Artdatabanekn) credentials?"
	@echo "If not please see redlist-rc-example.sh for an example."
	docker run --rm -it -v $(PWD):/home/rstudio \
		-w /home/rstudio \
		bioatlas/mirroreum:0.9.1 ./redlist.R

redlist-extra:
	 docker run --rm -it -v $(PWD):/home/rstudio \
		-w /home/rstudio \
		bioatlas/mirroreum:0.9.1 ./redlist-extra.R


