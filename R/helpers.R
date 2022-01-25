extract_stl_trend <- function(c,s.window=21,t.window=14){
  #print(length(c))
  cc <- c %>%
    ts(frequency = 7,start = as.numeric(format(Sys.Date(), "%j"))) %>% 
    stl(s.window=s.window,t.window=t.window) 
  
  as_tibble(cc$time.series)$trend
}

extract_stl_seasonal <- function(c,s.window=21,t.window=14){
  #print(length(c))
  cc <- c %>%
    ts(frequency = 7,start = as.numeric(format(Sys.Date(), "%j"))) %>% 
    stl(s.window=s.window,t.window=t.window) 
  
  as_tibble(cc$time.series)$seasonal
}


extract_stl_trend_m <- function(c,s.window=21,t.window=14){
  #print(length(c))
  cc <- c %>%
    log %>%
    ts(frequency = 7,start = as.numeric(format(Sys.Date(), "%j"))) %>% 
    stl(s.window=s.window,t.window=t.window) 
  
  as_tibble(cc$time.series)$trend %>% exp()
}

extract_stl_seasonal_m <- function(c,s.window=21,t.window=14){
  #print(length(c))
  cc <- c %>%
    log() %>%
    ts(frequency = 7,start = as.numeric(format(Sys.Date(), "%j"))) %>% 
    stl(s.window=s.window,t.window=t.window) 
  
  as_tibble(cc$time.series)$seasonal%>% exp()
}


add_stl_trend_m <- function(c,s.window=21,t.window=14){
  #print(length(c))
  cc <- c %>%
    log() %>%
    ts(frequency = 7,start = as.numeric(format(Sys.Date(), "%j"))) %>% 
    stl(s.window=s.window,t.window=t.window) 
  
  as_tibble(cc$time.series) %>%
    mutate_all(exp)
}

get_stl_trend_uncertainty <- function(c,s.window=21,t.window=14,level=0.8,gr_add=c(0,0)){
  #print(length(c))
  lc <- log(c)
  cc0 <- lc %>%
    ts(frequency = 7,start = as.numeric(format(Sys.Date(), "%j"))) %>% 
    stl(s.window=s.window,t.window=t.window) 
  
  sc <- as_tibble(cc0$time.series)$seasonal
  sa <- exp(lc-sc)
  pre_trend <- exp(as_tibble(cc0$time.series)$trend)
  
  fit21<-glm(c~d,data=tibble(c=tail(sa,21),d=seq(0,20)),family=quasipoisson(link = "log"))
  fit14<-glm(c~d,data=tibble(c=tail(sa,14),d=seq(0,13)),family=quasipoisson(link = "log"))
  fit7<-glm(c~d,data=tibble(c=tail(sa,7),d=seq(0,6)),family=quasipoisson(link = "log"))
  
  gr21 <- suppressMessages(fit14 %>% confint(level=level))
  gr14 <- suppressMessages(fit14 %>% confint(level=level))
  gr7 <- suppressMessages(fit7 %>% confint(level=level))
  
  
  
  anchor <- tibble(start=c(#log(pre_trend[length(pre_trend)-5])+5*gr21[2,],
    log(pre_trend[length(pre_trend)-3])+3*(gr14[2,]+gr_add),
    log(pre_trend[length(pre_trend)-3])+3*(gr7[2,]+gr_add)) %>% exp(),
    fit=c("fit14-","fit14+","fit7-","fit7+"),
    dd=length(c) %>% as.character,
    slope=c(#gr21[2,],
      gr14[2,],gr7[2,])) %>%
    complete(dd=seq(length(c),length(c)+7) %>% as.character,nesting(fit,start,slope)) %>%
    mutate(d=as.integer(dd)) %>%
    group_by(fit) %>%
    arrange(d) %>%
    mutate(s=sc[seq(length(sc)-7,length(sc))]) %>%
    ungroup %>%
    mutate(Cases=exp((log(start)+(d-length(c))*slope)+s)) %>%
    filter(d>length(c)) %>%
    bind_rows(tibble(Cases=c,fit="fit14-") %>% 
                mutate(d=row_number()) %>% 
                complete(fit=c("fit14-","fit14+","fit7-","fit7+"),nesting(Cases,d))) %>%
    arrange(fit,d) %>%
    select(d,Cases,fit)
  
  anchor <- anchor %>% 
    group_by(.data$fit) %>% 
    arrange(.data$d) %>%
    mutate(stl=add_stl_trend_m(Cases)) %>%
    mutate(trend=stl$trend)
  
  dd<-anchor %>% 
    arrange(d) %>%
    filter(d<=length(c)) %>%
    group_by(fit) %>%
    group_map(~ .x$stl %>% mutate(fit=.y$fit,d=.x$d)) %>%
    bind_rows()
  
  ddd<-dd %>% 
    left_join(tibble(Cases=c,pre_trend=pre_trend) %>% mutate(d=row_number()),by="d") %>%
    group_by(d) %>%
    mutate(diff=max(abs(pre_trend-trend))) %>%
    ungroup() %>%
    filter(d>=min(filter(.,diff>0.25)$d)-1) %>%
    group_by(d) %>%
    summarise(max=max(trend),min=min(trend),Cases=mean(Cases),pre_trend=mean(pre_trend),diff=mean(diff)) %>%
    ungroup %>%
    mutate(dm=d-max(d)) %>%
    mutate(min=pmin(min,pre_trend),
           max=pmax(max,pre_trend)) %>%
    select(d=dm,min,max)
}

get_stl_fan <- function(data,stl_floor=5,level=0.5,gr_add=c(-0.01,0.01)) {
  gs <- groups(data) %>% as.character() %>% syms
  data %>% 
    arrange(Date) %>%
    group_map(~get_stl_trend_uncertainty(.x$Cases+stl_floor,level=level,gr_add=gr_add) %>%
                mutate(HA=.y$HA,AG=.y$AG,HR=.y$HR)) %>%
    bind_rows() %>%
    mutate_at(c("min","max"),function(d)pmax(0,d-stl_floor)) %>%
    mutate(Date=max(data$Date)+d) %>%
    mutate(run=0) %>%
    complete(run=seq(0,5),nesting(!!!gs,Date,min,max)) %>%
    mutate(p=run/5) %>%
    mutate(value=min*p+max*(1-p))
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


graph_to_s3 <- function(graph,s3_bucket,s3_path,content_type="image/png",width=7,height=7,dpi = 150){
  tmp <- tempfile(fileext = ".png")
  ggsave(tmp,plot=graph,width=width,height=height,dpi = dpi)
  
  result <- aws.s3::put_object(file=tmp,
                               object=s3_path,
                               bucket=s3_bucket,
                               multipart = TRUE,
                               acl="public-read",
                               headers=list("Content-Type"=content_type,
                                            "Cache-Control"="no-cache",
                                            "Etag"=digest::digest(Sys.time())))
  
}

body_for_plant <- function(plant){
  paste0('<Request xmlns="http://schemas.microsoft.com/sharepoint/clientquery/2009" SchemaVersion="15.0.0.0" LibraryVersion="15.0.0.0" ApplicationName="Javascript Library"><Actions><ObjectPath Id="37" ObjectPathId="36" /><ObjectPath Id="39" ObjectPathId="38" /><ObjectPath Id="41" ObjectPathId="40" /><ObjectPath Id="43" ObjectPathId="42" /><ObjectPath Id="45" ObjectPathId="44" /><Query Id="46" ObjectPathId="44"><Query SelectAllProperties="false"><Properties /></Query><ChildItemQuery SelectAllProperties="false"><Properties><Property Name="InternalName" SelectAll="true" /><Property Name="TypeAsString" SelectAll="true" /></Properties></ChildItemQuery></Query><ObjectPath Id="49" ObjectPathId="48" /><Query Id="50" ObjectPathId="48"><Query SelectAllProperties="false"><Properties /></Query><ChildItemQuery SelectAllProperties="false"><Properties><Property Name="CalculatedDate" SelectAll="true" /><Property Name="Date" SelectAll="true" /><Property Name="Note" SelectAll="true" /><Property Name="Plant" SelectAll="true" /><Property Name="Value" SelectAll="true" /></Properties></ChildItemQuery></Query></Actions><ObjectPaths><StaticProperty Id="36" TypeId="{3747adcd-a3c3-41b9-bfab-4a64dd2f1e0a}" Name="Current" /><Property Id="38" ParentId="36" Name="Web" /><Property Id="40" ParentId="38" Name="Lists" /><Method Id="42" ParentId="40" Name="GetById"><Parameters><Parameter Type="String">5a8cb96f-9e2f-49f2-b863-65de98c03b33</Parameter></Parameters></Method><Property Id="44" ParentId="42" Name="Fields" /><Method Id="48" ParentId="42" Name="GetItems"><Parameters><Parameter TypeId="{3d248d7b-fc86-40a3-aa97-02a75d69fb8a}"><Property Name="DatesInUtc" Type="Boolean">true</Property><Property Name="FolderServerRelativeUrl" Type="Null" /><Property Name="ListItemCollectionPosition" Type="Null" /><Property Name="ViewXml" Type="String">&lt;View&gt;&#10;  &lt;ViewFields&gt;&#10;    &lt;FieldRef Name="LinkTitle" /&gt;&#10;    &lt;FieldRef Name="Plant" /&gt;&#10;    &lt;FieldRef Name="Date" /&gt;&#10;    &lt;FieldRef Name="Value" /&gt;&#10;    &lt;FieldRef Name="Note" /&gt;&#10;    &lt;FieldRef Name="CalculatedDate" /&gt;&#10;  &lt;/ViewFields&gt;&#10;  &lt;RowLimit Paged="TRUE"&gt;1000&lt;/RowLimit&gt;&#10;  &lt;Query&gt;&#10;    &lt;Where&gt;&lt;Eq&gt;        &lt;FieldRef Name="Plant" /&gt;        &lt;Value Type="text"&gt;',plant,'&lt;/Value&gt;    &lt;/Eq&gt;&lt;/Where&gt;&#10;    &lt;OrderBy&gt;&#10;      &lt;FieldRef Name="Date" Ascending="TRUE" /&gt;&#10;    &lt;/OrderBy&gt;&#10;  &lt;/Query&gt;&#10;&lt;/View&gt;&#10;</Property></Parameter></Parameters></Method></ObjectPaths></Request>')
}

get_data_for_plant <- function(plant){
  url <- "http://www.metrovancouver.org/services/liquid-waste/environmental-management/covid-19-wastewater/_vti_bin/client.svc/ProcessQuery"
  
  r<-httr::POST(url,body=body_for_plant(plant),
                httr::add_headers("Content-Type"="text/xml",
                                  "Accept"= "*/*",
                                  "Accept-Encoding"= "gzip, deflate",
                                  "X-Requested-With"= "XMLHttpRequest",
                                  "X-RequestDigest"=
                                    "0x1F23E733AF354BD8BA79396EE3A8F6307FDFB48F08B04BA9AA0005F58971EA9A936845E31FC3C144A447DA60DB6A6798F7AE8E054146DFE10F3A6A757929B5AA,21 Aug 2021 01:01:59 -0000"),
                httr::set_cookies("SPUsageId"="3332b361-25e6-4386-9dbc-eacf5c2212b5"))
  c<-httr::content(r)
  
  headers<- c("CalculatedDate","Plant","Value")
  c[[17]][["_Child_Items_"]] %>% 
    lapply(function(e){
      #as_tibble(e[headers])
      v<-e$Value
      if (is.null(v)) v <- NA
      tibble(Date=gsub("\\/Date\\(|\\)\\/","",e$Date),
             CalculatedDate=e$CalculatedDate,
             Plant=e$Plant,
             Version=e$`_ObjectVersion_`,
             Value=v)
      }) %>%
    bind_rows() %>%
    mutate(DateTime=as.POSIXct(as.numeric(Date)/1000, 
                               origin="1970-01-01", tz="America/Vancouver")) %>%
    mutate(Date=as.Date(CalculatedDate,format="%Y/%m/%d")) 
}
