#! make

all: build up browse

build:
	docker build -t bioatlas/scibearserver .

rebuild:
	docker build --no-cache -t bioatlas/scibearserver .

reload:
	docker-compose restart api

up:
	docker-compose up -d

down:
	docker-compose down

browse:
	#curl -s https://data.bioatlas.se/scibears?n=2600 > scibears.json

	firefox https://data.bioatlas.se/__swagger__/ &
	firefox https://data.bioatlas.se/scibears?n=2600 &

	firefox https://maps.bioatlas.se/__swagger__/ &
	firefox https://maps.bioatlas.se/scibears &

scale-down:
	docker-compose scale api=1

scale-up:
	docker-compose scale api=3

stress:
	ab -n 400 -c 4 -l https://data.bioatlas.se/scibears


