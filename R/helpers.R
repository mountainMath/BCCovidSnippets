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
    lapply(function(e)as_tibble(e[headers])) %>%
    bind_rows() %>%
    mutate(Date=as.Date(CalculatedDate,format="%Y/%m/%d"))
}
