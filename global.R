if (!require("RSQLite")) {
  install.packages("RSQLite", repos="http://cran.rstudio.com/") 
  library("RSQLite") 
}
if (!require("igraph")) {
  install.packages("igraph", repos="http://cran.rstudio.com/") 
  library("igraph") 
}
if (!require("stringr")) {
  install.packages("stringr", repos="http://cran.rstudio.com/") 
  library("stringr") 
}
if (!require("tm")) {
  install.packages("tm", repos="http://cran.rstudio.com/") 
  library("tm") 
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
retweets <- function(y,z) {
  #require(igraph)
  DF <- y
  # List the most influential accounts
  #print(head(paste(DF$username,DF$followers)[rev(order(DF$followers))],n <- 50))
  # Clean text of tweets 
  DF$text <- sapply(DF$content,function(row) iconv(row,to='UTF-8')) #remove odd characters
  trim <- function (x) sub('@','',x) # remove @ symbol from user names 
  # Extract retweets
  #library(stringr)
  DF$rt <- sapply(DF$text,function(tweet) trim(str_match(tweet,"^RT (@[[:alnum:]_]*)")[2]))      
  # basic analysis and visualisation of RT'd messages
  #sum(!is.na(DF$rt))                # see how many tweets are retweets
  #sum(!is.na(DF$rt))/length(DF$rt)  # the ratio of retweets to tweets
  #countRT <- table(DF$rt)
  #countRT <- sort(countRT)
  #countRT.subset <- subset(countRT,countRT >2) # subset those RTd at least twice
  #barplot(countRT.subset,las=2,cex.names = 0.75) # plot them
  #  basic social network analysis using RT 
  rt <- data.frame(user=DF$username, rt=DF$rt) # tweeter-retweeted pairs
  rt.u <- na.omit(unique(rt)) # omit pairs with NA, get only unique pairs
  # begin sna
  g <- graph.data.frame(rt.u, directed = T)
  bad.vs <- V(g)[degree(g) < as.numeric(z)]
  ng <- delete.vertices(g, bad.vs)
  V(ng)$size=degree(ng)*5
  V(ng)$color=degree(ng)+1
  #V(ng)$label.cex <- degree(ng)*0.8
  #V(ng)$weight=degree(ng)
  ng <<- simplify(ng)
  #ecount(g) # edges (connections)
  #vcount(g) # vertices (nodes)
  #diameter(g) # network diameter
  #farthest.nodes(g) # show the farthest nodes
  #tkplot(g)
  #write.graph(g,'./rtnetwork.graphml',format <- 'graphml')
}
#hashtags <- function(x) {
#  ht <- unlist(strsplit(tolower(DF$hashtag), ","))
#  ht <- tapply(ht,INDEX = ht,FUN=table)
#  ht <<- as.data.frame(as.table(ht))
#  names(ht) <- c('hashtag','frequency')
  #plot(ht)
#}