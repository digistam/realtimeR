if (!require("RSQLite")) {
  install.packages("RSQLite", repos="http://cran.rstudio.com/") 
  library("RSQLite") 
}
DF <- data.frame(replicate(18,sample(0:1,20,rep=TRUE)))
names(DF) <- c("id",         "tid",        "username",   "statuses",   "since",      "followers", 
               "friends",    "location",   "utc_offset", "created_at","content",    "geo",       
               "meta",       "hashtags",   "urls",       "media",      "source",     "lang")  
connectSQL <- function(x) {
  set.seed(111)
  drv <<- dbDriver("SQLite")
  con <<- dbConnect(drv, x)
  dbListTables(con)
}
queryTable <- function(x) {
  set.seed(111)
  q <- dbGetQuery(con, paste("SELECT * FROM ", x, "", sep=""))
  DF <<- as.data.frame(q)
}
##-----------------------------------------------------------------------------------
## Subset large datasets
## ----------------------------------------------------------------------------------

subsetDF <- function(x) {
  subDF <<- DF[grep(x,DF$content),]
}