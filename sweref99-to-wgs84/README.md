# Coordinate conversion

A couple of example R scripts are included here.

One script has a function to synthesize data to conform with a particular format - used for scientific reporting of bear observations in Sweden. The other script is a frontend component - a client of that API - a map application. It uses the API to get JSON data and then does coordinate conversions to convert coordinates into WGS84 and displays the data on a map (using leaflet). 

The two functions are deployed as web services using the plumber package as separate micro services using the same base image. The containers can be scaled up and down and stress tested using `ab` from apache2-utils (`apt install apache2-utils`).


## Usage

The Makefile can be used to scale the api and put some load on the API:

		make
		make scale-up
		make stress



