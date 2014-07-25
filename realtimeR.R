# realtimeR.R
# Author: Mark Stam
# Date: 25-07-2014

connectSQL <- function(x) {
  require("RSQLite")
  drv <<- dbDriver("SQLite")
  con <<- dbConnect(drv, x)
  dbListTables(con)
  #dbDisconnect(con)
}

queryTable <- function(x) {
  q <- dbGetQuery(con, paste("SELECT * FROM ", x, "", sep=""))
  DF <<- as.data.frame(q)
}

topUsers <- function(x) {
  head(sort(table(DF$username),decreasing=T),10)
}
