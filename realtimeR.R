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

##-----------------------------------------------------------------------------------
## Text mining
## credits: http://heuristically.wordpress.com/2011/04/08/text-data-mining-twitter-r/
##
## A dendrogram (from Greek dendron "tree" and gramma "drawing") is a tree diagram 
## frequently used to illustrate the arrangement of the clusters produced by hierarchical 
## clustering. 
## ----------------------------------------------------------------------------------

install.packages('tm')
require(tm)
## Text mining positive tweets
pos.tweets.corpus <- Corpus(VectorSource(pos.tweets$content))
pos.tweets.corpus <- tm_map(pos.tweets.corpus, tolower)
pos.tweets.corpus <- tm_map(pos.tweets.corpus, removePunctuation)
pos.tweets.stopwords <- c(stopwords('english'))
pos.tweets.corpus <- tm_map(pos.tweets.corpus, removeWords, pos.tweets.stopwords)
pos.tweets.dtm <- TermDocumentMatrix(pos.tweets.corpus)
pos.tweets.dtm
findFreqTerms(pos.tweets.dtm, lowfreq=30) ## find frequent words
findAssocs(pos.tweets.dtm, 'mh17', 0.20)
pos.tweets.dtm2 <- removeSparseTerms(pos.tweets.dtm, sparse=0.95)
pos.tweets.df <- as.data.frame(inspect(pos.tweets.dtm2))
nrow(pos.tweets.df)
ncol(pos.tweets.df)
pos.tweets.df.scale <- scale(pos.tweets.df)
pos.d <- dist(pos.tweets.df.scale, method = "euclidean") # distance matrix
pos.fit <- hclust(pos.d, method="ward")
plot(pos.fit) # display dendogram?
groups <- cutree(pos.fit, k=5) # cut tree into 5 clusters
# draw dendogram with red borders around the 5 clusters
rect.hclust(pos.fit, k=5, border="red")

## Text mining negative tweets
neg.tweets.corpus <- Corpus(VectorSource(neg.tweets$content))
neg.tweets.corpus <- tm_map(neg.tweets.corpus, tolower)
neg.tweets.corpus <- tm_map(neg.tweets.corpus, removePunctuation)
neg.tweets.stopwords <- c(stopwords('english')) ## add more if needed
neg.tweets.corpus <- tm_map(neg.tweets.corpus, removeWords, neg.tweets.stopwords)
neg.tweets.dtm <- TermDocumentMatrix(neg.tweets.corpus)
neg.tweets.dtm ## run to see contents
findFreqTerms(neg.tweets.dtm, lowfreq=30) ## find frequent words
findAssocs(neg.tweets.dtm, 'mh17', 0.20)
neg.tweets.dtm2 <- removeSparseTerms(neg.tweets.dtm, sparse=0.95)
neg.tweets.df <- as.data.frame(inspect(neg.tweets.dtm2))
nrow(neg.tweets.df)
ncol(neg.tweets.df)
neg.tweets.df.scale <- scale(neg.tweets.df)
neg.d <- dist(neg.tweets.df.scale, method = "euclidean") # distance matrix
neg.fit <- hclust(neg.d, method="ward")
plot(neg.fit) # display dendogram?
groups <- cutree(neg.fit, k=5) # cut tree into 5 clusters
# draw dendogram with red borders around the 5 clusters
rect.hclust(neg.fit, k=5, border="red")

