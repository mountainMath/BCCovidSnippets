BC Covid Trends
================
Jens von Bergmann
Last updated at 05 January, 2021 - 19:26

This notebook is intended to give a daily overview over BC Covid Trends.
It utilizes a (multiplicative) STL decomposition to esimate a seasonally
adjusted time series controlling for the strong weekly pattern in the
COVID-19 case data and the trend line. For details check the [R notebook
in this GitHub
repo](https://github.com/mountainMath/BCCovidSnippets/blob/main/bc_covid_trends.Rmd).

## Overall BC Trend

![](https://bccovid.s3.ca-central-1.amazonaws.com/bc-trend.png)

## Main Health Authority Trends

![](https://bccovid.s3.ca-central-1.amazonaws.com/main-ha-trend.png)

## Health Authority Trends

![](https://bccovid.s3.ca-central-1.amazonaws.com/ha-trend.png)

## Health Region Trends

![](https://bccovid.s3.ca-central-1.amazonaws.com/hr-trend.png)

### Health Region geocoding problems

Health Authorities may lag in geocoding cases to Health Region
geographies, which makes the above Health Region level graph difficult
to interpret. This graph shows the share of cases in each Health
Authority that were geocoded to Health Region geographies.

![](https://bccovid.s3.ca-central-1.amazonaws.com/hr-check.png)
