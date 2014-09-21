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
if (!require("plyr")) {
  install.packages("plyr", repos="http://cran.rstudio.com/") 
  library("plyr") 
}
if (!require("tm")) {
  install.packages("tm", repos="http://cran.rstudio.com/") 
  library("tm") 
}
if (!require("wordcloud")) {
  install.packages("wordcloud", repos="http://cran.rstudio.com/") 
  library("wordcloud") 
}

DF <- data.frame(replicate(18,sample(0:1,20,rep=TRUE)))
names(DF) <- c("id",         "tid",        "username",   "statuses",   "since",      "followers", 
               "friends",    "location",   "utc_offset", "created_at","content",    "geo",       
               "meta",       "hashtags",   "urls",       "media",      "source",     "lang")  
DF <- DF[ order(-rank(DF[10])), ]
#tempTt = scan('www/temp.txt',what='character', comment.char=';')
words = c('temp')
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
m_retweets <- function(y,z) {
  #require(igraph)
  DF <- y
  # List the most influential accounts
  #print(head(paste(DF$username,DF$followers)[rev(order(DF$followers))],n <- 50))
  # Clean text of tweets 
  DF$text <- sapply(DF$content,function(row) iconv(row,to='UTF-8')) #remove odd characters
  trim <- function (x) sub('@','',x) # remove @ symbol from user names 
  # Extract retweets
  #library(stringr)
  DF$rt <- sapply(DF$text,function(tweet) trim(str_match(tweet,"(@[[:alnum:]_]*)")[2]))      
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
  m_ng <<- simplify(ng)
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
textMine <- function(x) {
  DF.corpus <- Corpus(VectorSource(x))
  DF.corpus <- tm_map(DF.corpus, removePunctuation)
  DF.stopwords <- c(stopwords('english'), stopwords('dutch'))
  DF.corpus <- tm_map(DF.corpus, removeWords, DF.stopwords)
  DF.dtm <<- TermDocumentMatrix(DF.corpus,control = list(wordLengths = c(3,10)))
}
wordCloud <- function(x,y,z) {
  m <- as.matrix(x)
  v <- sort(rowSums(m), decreasing=TRUE)
  DFnames <- names(v)
  d <- data.frame(word=DFnames, freq=v)
  wordcloud_rep <- repeatable(wordcloud)
  #png("www/wordcloud.png", width=1280,height=800,res=300)
  #wordcloud_rep(d$word, d$freq, min.freq = y, max.words=z, colors=brewer.pal(8, "Dark2")) 
  wordcloud(d$word,d$freq, scale=c(3.5,1.5),min.freq = y, max.words=z, random.order=T, rot.per=.15, colors=brewer.pal(8, "Dark2"))
  #dev.off()
}
score.threats <- function(sentences, threat.words, .progress='none')
{
  require(plyr)
  require(stringr)
  
  # we got a vector of sentences. plyr will handle a list
  # or a vector as an "l" for us
  # we want a simple array of scores back, so we use
  # "l" + "a" + "ply" = "laply":
  scores = laply(sentences, function(sentence, threat.words) {
    
    # clean up sentences with R's regex-driven global substitute, gsub():
    sentence = gsub('[[:punct:]]', '', sentence)
    sentence = gsub('[[:cntrl:]]', '', sentence)
    sentence = gsub('\\d+', '', sentence)
    # and convert to lower case:
    sentence = tolower(sentence)
    
    # split into words. str_split is in the stringr package
    word.list = str_split(sentence, '\\s+')
    # sometimes a list() is one level of hierarchy too much
    words = unlist(word.list)
    
    # compare our words to the dictionaries of positive & negative terms
    matches = match(words, threat.words)
    
    # match() returns the position of the matched term or NA
    # we just want a TRUE/FALSE:
    matches = !is.na(matches)
    
    # and conveniently enough, TRUE/FALSE will be treated as 1/0 by sum():
    score = sum(matches)
    
    return(score)
  }, words, .progress=.progress )
  
  scores.df = data.frame(score=scores, text=sentences)
  return(scores.df)
}

showScores <- function(x) {
  tt = scan(x,what='character', comment.char=';')
  words <<- c(tt)
  tweet.scores <- score.threats(DF$content, words, .progress='text')
  score <<- tweet.scores$score
  dd <<- cbind(score,DF)
}
