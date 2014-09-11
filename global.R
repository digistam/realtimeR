if (!require("RSQLite")) {
  install.packages("RSQLite", repos="http://cran.rstudio.com/") 
  library("RSQLite") 
}
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

#connectSQL('jihaad.db')
#queryTable('politie')