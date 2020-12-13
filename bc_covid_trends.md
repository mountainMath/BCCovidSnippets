BC Covid Trends
================
Last updated at 13 December, 2020 - 18:07

This notebook is intended to give a daily overview over BC Covid Trends.
It utilizes a (multiplicative) STL decomposition to esimate a seasonally
adjusted time series controlling for the strong weekly pattern in the
COVID-19 case data and the trend line. For details check the [R notebook
in this GitHub
repo](https://github.com/mountainMath/BCCovidSnippets/blob/main/bc_covid_trends.Rmd).

## Overall BC Trend

<img src="bc_covid_trends_files/figure-gfm/bc-trend-1.png" width="2100" />

## Main Health Authority Trends

<img src="bc_covid_trends_files/figure-gfm/main-ha-trend-1.png" width="2100" />

## Health Authority Trends

<img src="bc_covid_trends_files/figure-gfm/ha-trend-1.png" width="2100" />

## Health Region Trends

<img src="bc_covid_trends_files/figure-gfm/hr-tren-1.png" width="2100" />

### Health Region geocoding problems

Health Authorities may lag in geocoding cases to Health Region
geographies, which makes the above Health Region level graph difficult
to interpret. This graph shows the share of cases in each Health
Authority that were geocoded to Health Region geographies.

<img src="bc_covid_trends_files/figure-gfm/hr-check-1.png" width="2100" />
