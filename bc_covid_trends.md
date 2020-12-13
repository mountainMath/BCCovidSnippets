BC Covid Trends
================
13 December, 2020

This notebook is intended to give a daily overview over BC Covid Trends.
It utilizes a (multiplicative) STL decomposition to esimate a seasonally
adjusted time series controlling for the strong weekly pattern in the
COVID-19 case data and the trend line. For details check the [R notebook
in this GitHub
repo](https://github.com/mountainMath/BCCovidSnippets/blob/main/bc_covid_trends.Rmd).

## Overall BC Trend

![](bc_covid_trends_files/figure-gfm/unnamed-chunk-1-1.png)<!-- -->

![](bc_covid_trends_files/figure-gfm/unnamed-chunk-2-1.png)<!-- -->

## Health Authority Trends

![](bc_covid_trends_files/figure-gfm/unnamed-chunk-3-1.png)<!-- -->

## Health Region Trends

![](bc_covid_trends_files/figure-gfm/unnamed-chunk-4-1.png)<!-- -->

### Health Region geocoding problems

Health Authorities may lag in geocoding cases to Health Region
geographies, which makes the above Health Region level graph difficult
to interpret. This graph shows the share of cases in each Health
Authority that were geocoded to Health Region geographies.

![](bc_covid_trends_files/figure-gfm/unnamed-chunk-5-1.png)<!-- -->
