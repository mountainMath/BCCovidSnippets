extract_stl_trend <- function(c){
  #print(length(c))
  cc <- c %>%
    ts(frequency = 7,start = as.numeric(format(Sys.Date(), "%j"))) %>% 
    stl(s.window=14,t.window=14) 
  
  as_tibble(cc$time.series)$trend
}

extract_stl_seasonal <- function(c){
  #print(length(c))
  cc <- c %>%
    ts(frequency = 7,start = as.numeric(format(Sys.Date(), "%j"))) %>% 
    stl(s.window=14,t.window=14) 
  
  as_tibble(cc$time.series)$seasonal
}


extract_stl_trend_m <- function(c){
  #print(length(c))
  cc <- c %>%
    log %>%
    ts(frequency = 7,start = as.numeric(format(Sys.Date(), "%j"))) %>% 
    stl(s.window=14,t.window=14) 
  
  as_tibble(cc$time.series)$trend %>% exp()
}

extract_stl_seasonal_m <- function(c){
  #print(length(c))
  cc <- c %>%
    log() %>%
    ts(frequency = 7,start = as.numeric(format(Sys.Date(), "%j"))) %>% 
    stl(s.window=14,t.window=14) 
  
  as_tibble(cc$time.series)$seasonal%>% exp()
}

compute_rolling_exp_fit <- function(r,window_width=7,min_obs=window_width-1,se=3){
  reg<-roll::roll_lm(seq(1,length(r)),log(r),width=window_width,min_obs=min_obs)
  reg$coefficients %>%
    as_tibble %>%
    select(shift=`(Intercept)`,slope=x1) %>%
    cbind(reg$std.error %>%
            as_tibble %>%
            select(shift_e=`(Intercept)`,slope_e=x1)) %>%
    mutate(low=slope-se*slope_e,high=slope+se*slope_e) %>%
    select(r=slope,low,high)
}

clean_missing_weekend_data <- function(tl){
  zeros <- which(tl==0)
  blocks <- which(!(zeros %in% (zeros+1)))
  lengths <-lead(blocks)-blocks
  lengths[length(lengths)]=length(zeros[zeros>=zeros[blocks[length(blocks)]]])
  for (i in seq(1,length(blocks))){
    b=zeros[blocks[i]]
    l=lengths[i]
    e=b+l
    if (e>length(tl)) {
      l=l-1
      e=e-1
    }
    v=tl[e]/(l+1)
    for (j in seq(0,l)) {
      tl[b+j]=v
    }
  }
  tl
}



get_british_columbia_case_data <- function(){
  path="http://www.bccdc.ca/Health-Info-Site/Documents/BCCDC_COVID19_Dashboard_Case_Details.csv"
  read_csv(path,col_types=cols(.default="c")) %>%
    rename(`Reported Date`=Reported_Date,`Health Authority`=HA,`Age group`=Age_Group) %>%
    mutate(`Age group`=recode(`Age group`,"19-Oct"="10-19")) %>%
    mutate(`Reported Date`=as.Date(`Reported Date`,tryFormats = c("%Y-%m-%d", "%m/%d/%Y")))
}

get_british_columbia_hr_case_data <- function(){
  path="http://www.bccdc.ca/Health-Info-Site/Documents/BCCDC_COVID19_Regional_Summary_Data.csv"
  read_csv(path,col_types=cols(.default="c")) %>%
    rename(`Health Authority`=HA,`Health Region`=HSDA,Cases=Cases_Reported,`Cases Smoothed` =Cases_Reported_Smoothed ) %>%
    mutate(Date=as.Date(Date,tryFormats = c("%Y-%m-%d", "%m/%d/%Y"))) %>%
    mutate_at(c("Cases","Cases Smoothed"),as.numeric)
}