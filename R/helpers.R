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


graph_to_s3 <- function(graph,s3_bucket,s3_path,content_type="image/png"){
  tmp <- tempfile(fileext = ".png")
  ggsave(tmp,plot=graph)
  mountainmathHelpers::file_to_s3(tmp,s3_bucket,s3_path,content_type)
}

