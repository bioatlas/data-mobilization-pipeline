# Coordinate conversion

A couple of example R scripts are included here.

One script synthesize data to conform with a particular format - used for scientific reporting of bear observations in Sweden.

That is deployed as an API using the plumber R-package.

The other script is a frontend component - a client of that API - a map application. It does coordinate conversions to convert coordinates into WGS84 and displays the data on a map (leaflet).

It is also deployed using the plumber package, as an interactive web map, displaying the data from the API.

## Usage

The Makefile can be used to scale the api and put some load on the API:

		make scale-up
		make stress



