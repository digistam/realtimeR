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

##-----------------------------------------------------------------------------------
## reTweet network function
## credits: http://stackoverflow.com/questions/10427147/retweet-count-for-specific-tweet
##
## ----------------------------------------------------------------------------------
#install.packages('igraph')
retweets <- function(y) {
require(igraph)
DF <- y
# Clean text of tweets 
DF$text <- sapply(DF$content,function(row) iconv(row,to='UTF-8')) #remove odd characters
trim <- function (x) sub('@','',x) # remove @ symbol from user names 
# Extract retweets
library(stringr)
DF$rt <- sapply(DF$text,function(tweet) trim(str_match(tweet,"^RT (@[[:alnum:]_]*)")[2]))      
# basic analysis and visualisation of RT'd messages
sum(!is.na(DF$rt))                # see how many tweets are retweets
sum(!is.na(DF$rt))/length(DF$rt)  # the ratio of retweets to tweets
countRT <- table(DF$rt)
countRT <- sort(countRT)
countRT.subset <- subset(countRT,countRT >2) # subset those RTd at least twice
barplot(countRT.subset,las=2,cex.names = 0.75) # plot them
#  basic social network analysis using RT 
rt <- data.frame(user=DF$username, rt=DF$rt) # tweeter-retweeted pairs
rt.u <- na.omit(unique(rt)) # omit pairs with NA, get only unique pairs
# begin sna
g <- graph.data.frame(rt.u, directed = T)
ecount(g) # edges (connections)
vcount(g) # vertices (nodes)
diameter(g) # network diameter
farthest.nodes(g) # show the farthest nodes
tkplot(g)
}

##-----------------------------------------------------------------------------------
## sentiment analysis
## credits: http://www.inside-r.org/howto/mining-twitter-airline-consumer-sentiment
##
## ----------------------------------------------------------------------------------

score.sentiment <- function(sentences, pos.words, neg.words, .progress='none')
{
  require(plyr)
  require(stringr)
  
  # we got a vector of sentences. plyr will handle a list
  # or a vector as an "l" for us
  # we want a simple array of scores back, so we use
  # "l" + "a" + "ply" = "laply":
  scores = laply(sentences, function(sentence, pos.words, neg.words) {
    
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
    pos.matches = match(words, pos.words)
    neg.matches = match(words, neg.words)
    
    # match() returns the position of the matched term or NA
    # we just want a TRUE/FALSE:
    pos.matches = !is.na(pos.matches)
    neg.matches = !is.na(neg.matches)
    
    # and conveniently enough, TRUE/FALSE will be treated as 1/0 by sum():
    score = sum(pos.matches) - sum(neg.matches)
    
    return(score)
  }, pos.words, neg.words, .progress=.progress )
  
  scores.df = data.frame(score=scores, text=sentences)
  return(scores.df)
}
hu.liu.pos = scan('positive-words.txt',what='character', comment.char=';')
hu.liu.neg = scan('negative-words.txt',what='character', comment.char=';')
pos.words = c(hu.liu.pos)
neg.words = c(hu.liu.neg)
tweet.scores = score.sentiment(DF$content, pos.words, neg.words, .progress='text')

## subsetting neg tweets
neg.tweets <- DF[tweet.scores == -4 | tweet.scores == -5,]
## subsetting pos tweets
pos.tweets <- DF[tweet.scores == 4 | tweet.scores == 5,]

print(paste('percentage positive tweets: ',nrow(pos.tweets) / sum(nrow(DF)) * 100))
print(paste('percentage negative tweets: ',nrow(neg.tweets) / sum(nrow(DF)) * 100))
retweets(pos.tweets)
retweets(neg.tweets)

##-----------------------------------------------------------------------------------
## Text mining
## credits: http://heuristically.wordpress.com/2011/04/08/text-data-mining-twitter-r/
##
## ----------------------------------------------------------------------------------

#install.packages('tm')
textmine <- function(y,z) {
  require(tm)
  DF <- y
  ## Text mining positive tweets
  DF.corpus <- Corpus(VectorSource(DF$content))
  DF.corpus <- tm_map(DF.corpus, tolower)
  DF.corpus <- tm_map(DF.corpus, removePunctuation)
  DF.stopwords <- c(stopwords('english'), stopwords('dutch'))
  DF.corpus <- tm_map(DF.corpus, removeWords, DF.stopwords)
  DF.dtm <- TermDocumentMatrix(DF.corpus,control = list(wordLengths = c(3,10)))
  #DF.dtm
  ## find frequent words
  findFreqTerms(DF.dtm, lowfreq=30) 
  ## In corpus linguistics, a collocation is a sequence of words or terms 
  ## that co-occur more often than would be expected by chance. 
  findAssocs(DF.dtm, z, 0.20)
  ## The number under each word is an association score, so the search term 
  ## always occurs with the search term. In some applications, a stemmer or 
  ## spell checker could help with misspelled words like “believeing.”
  ##
  ## To make a Hierarchical Agglomerative cluster plot, we need to reduce 
  ## the number of terms (which otherwise wouldn’t fit on a page or the screen) 
  ## and build a data frame.
  ## remove sparse terms to simplify the cluster plot
  ## Note: tweak the sparse parameter to determine the number of words.
  ## About 10-30 words is good.
  DF.dtm2 <- removeSparseTerms(DF.dtm, sparse=0.95)
  ## convert the sparse term-document matrix to a standard data frame
  DF.df <- as.data.frame(inspect(DF.dtm2))
  ## inspect dimensions of the data frame
  ##nrow(DF.df)
  ##ncol(DF.df)
  ## Now the data frame contains a bag of words (specifically, 1-grams) 
  ## which are simple frequency counts. Though the structure is lost, 
  ## it retains much information and is simple to use. The data frame 
  ## is ready for cluster analysis using a cluster analysis function 
  ## available in R core.
  DF.df.scale <- scale(DF.df)
  ## distance matrix
  pos.d <- dist(DF.df.scale, method = "euclidean")
  pos.fit <- hclust(pos.d, method="ward")
  plot(pos.fit) 
  ## display dendogram
  ## A dendrogram (from Greek dendron "tree" and gramma "drawing") is a tree diagram 
  ## frequently used to illustrate the arrangement of the clusters produced by hierarchical 
  ## clustering. 
  ## Cut tree into 5 clusters
  groups <- cutree(pos.fit, k=5) 
  # draw dendogram with red borders around the 5 clusters
  rect.hclust(pos.fit, k=5, border="red")
  ## The terms higher in the plot are more popular, and terms close to each other 
  ## are more associated 
}

## To Do: text mining koppelen aan dreigingslijst / loodslijst en hiervan dendrogrammen etc. maken
