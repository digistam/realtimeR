options(shiny.maxRequestSize=30*1024^2)
if (!require("shiny")) {
  install.packages("shiny", repos="http://cran.rstudio.com/") 
  library("shiny") 
}
if (!require(devtools)) {
  install.packages("devtools")
  devtools::install_github("rstudio/shiny-incubator")
}
library(shinyIncubator)
if (!require("googleVis")) {
  install.packages("googleVis", repos="http://cran.rstudio.com/") 
  library("googleVis") 
}
library(tm)
if (!require("tm")) {
  install.packages("tm", repos="http://cran.rstudio.com/") 
  library("tm") 
}
library(lubridate)
if (!require("lubridate")) {
  install.packages("lubridate", repos="http://cran.rstudio.com/") 
  library("lubridate") 
}
shinyServer(function(input, output, session) {
  observe({
    inFile<-input$dbfile
    print(inFile)
    if(is.null(inFile))
      return(NULL)
    connectSQL(inFile$datapath)
    dbtbl <- dbListTables(con)
    updateSelectizeInput(session, 'database_tables', choices = dbtbl)
    
    
    
    ## show text after button click
    tableListbox <- function() {
      output$tables <- renderPrint({
        input$goButton
        isolate({
          tableName <<- input$database_tables
          output$Time_myKeyword <- renderPrint(tableName)
          output$Inf_myKeyword <- renderPrint(tableName)
          output$Hist_myKeyword <- renderPrint(cat(tableName))
          output$Rt_myKeyword <- renderPrint(cat(tableName))
          output$Words_myKeyword <- renderPrint(cat(tableName))
          isolate(cat(tableName))
        })
        
      }) 
    }
    tableListbox()
    
    output$tweets <- renderDataTable({
      input$goButton
      isolate({
        q <- dbGetQuery(con, paste("SELECT * FROM ", tableName, " ORDER BY created_at DESC", sep=""))
        DF <- as.data.frame.matrix(q)
        DF$created_at <- as.POSIXct(DF$created_at,format = "%Y-%m-%d %H:%M:%S", tz = "UTC")
        DF$created_at <- with_tz(DF$created_at, "Europe/Paris")
        #DF$created_at <- as.POSIXct(DF$created_at,format = "%Y-%m-%d %H:%M:%S", tz = "GMT")
        DF$followers <- as.numeric(DF$followers)
        DF <<- DF
        DF
      })
      
      DF[, input$show_vars, drop = FALSE]
      
    })
    
    output$influence <- renderDataTable({
      input$goButton
      isolate({
        withProgress(session, {
          setProgress(message = "Calculating, please wait",
                      detail = "This may take a few moments...")
          Sys.sleep(1)
          setProgress(detail = "Still working...")
#           mn <- tapply(paste(DF$username,DF$followers),INDEX = paste(DF$username,'(',DF$followers,'followers )'),FUN=table)
#           tbl <- as.data.frame(as.table(mn))
#           names(tbl) <- c('Account','Frequency')
#           tbl <- tbl[order(tbl$Frequency, decreasing = T),]
          mn <- tapply(paste(DF$username,DF$followers),INDEX = paste(DF$username,'|',DF$followers),FUN=table)
          tbl <- as.data.frame(as.table(mn))
          names(tbl) <- c('name','freq')
          tbl_split <- data.frame(do.call('rbind', strsplit(as.character(tbl$name),'|',fixed=TRUE)))
          tbl <- cbind(as.numeric(tbl$freq),tbl_split)
          names(tbl) <- c('Frequency','Account','Followers')
          tbl <- tbl[order(tbl$Frequency, decreasing = T),]
          setProgress(detail = "Almost there...")
          df <- tbl
          
        })})
    })
    ## hashtags ##
    output$hashtags <- renderDataTable({
      input$goButton
      isolate({
        withProgress(session, {
          setProgress(message = "Calculating, please wait",
                      detail = "This may take a few moments...")
          Sys.sleep(1)
          setProgress(detail = "Still working...")
          #hashtags()
          ht <- unlist(strsplit(tolower(str_trim(DF$hashtag)), ","))
          ht <- str_replace_all(string=ht, pattern=" ", repl="")
          ht <- tapply(ht,INDEX = ht,FUN=table)
          ht <- as.data.frame(as.table(ht))
          names(ht) <- c('hashtag','frequency')
          setProgress(detail = "Almost there...")
          ht[ order(-ht[2]), ] ## order by column number
        })})
    })
    ##
    output$histfollow <- renderGvis({
      input$goButton
      isolate({
        withProgress(session, {
          setProgress(message = "Calculating, please wait",
                      detail = "This may take a few moments...")
          Sys.sleep(1)
          setProgress(detail = "Still working...")
          dfFoll <- as.data.frame(DF$followers)
          setProgress(detail = "Almost there...")
          ( 
            gvisHistogram(dfFoll, options=list(
              title = "Followers Count",
              legend="{ position: 'none', maxLines: 2 }",
              colors="['#871B47']",
              width='100%',
              chartid="Histogram",
              fontSize="10"
            )
            )
          )})
      })})
    
    if (input$useSlider != TRUE) {
      bias <- input$nodes
      bias <- bias * 3600
    } else { bias <- 3600000000000000000}
    output$sliderinfo <- renderText(bias)
    output$timeSeries <- renderGvis({
      input$goButton
      isolate({
        # Wrap the entire expensive operation with withProgress
        withProgress(session, {
          setProgress(message = "Calculating, please wait",
                      detail = "This may take a few moments...")
          Sys.sleep(1)
          setProgress(detail = "Still working...")
          
          ttt <- DF$created_at #as.POSIXct(DF$created_at,format = "%Y-%m-%d %H:%M:%S CEST") 
          uuu <- Sys.time() - bias
          vvv <- ttt[ttt > uuu]
          t2 <- strptime(vvv, format="%Y-%m-%d %H:%M")
          t2$min <- round(t2$min, -1)
          ddd <- as.character(t2)
          eee <- tapply(ddd,INDEX = ddd,FUN=table)
          fff <- as.data.frame(as.table(eee))
          names(fff) <- c('Account','Frequency')
          df <- data.frame(a=fff$Account, tweets=fff$Frequency)
          Sys.sleep(1)
          setProgress(detail = "Almost there...")
          Sys.sleep(1)
          setProgress(detail = "Creating timeline ...")
          Sys.sleep(1)
          gvisLineChart(df, xvar="a", yvar=c("tweets"),options=list(
            title="Trendline",
            fontSize = 10))
          
        })   }) 
    })
    
    ## retweet network
    retweets(DF,input$edges) ## function from global
    output$retweetNetwork <- renderTable({
      input$goButton
      isolate({
        withProgress(session, {
          setProgress(message = "Calculating, please wait",
                      detail = "This may take a few moments...")
          Sys.sleep(1)
          setProgress(detail = "Still working...")
          
          as.matrix(get.adjacency(ng))
          
        })})
    })
    
    output$nodeCount <- renderText({
      input$goButton
      isolate({
        withProgress(session, {
          setProgress(message = "Calculating, please wait", detail = "This may take a few moments...")
          Sys.sleep(1)
          retweets(DF,input$edges)
          setProgress(detail = "Still working...")
          output$nodeCount <- renderText({vcount(ng)})
          Sys.sleep(1)
          setProgress(detail = "Almost finished ...")
          Sys.sleep(1)
          output$edgeCount <- renderText({ecount(ng)})
          output$density <- renderText({graph.density(ng)})
          output$diameter <- renderText({diameter(ng)})
          output$clusters <- renderText({clusters(ng)$no})
        })
      })
      
      ## mention network
      output$m_nodeCount <- renderText({
        input$goButton
        isolate({
          m_retweets(DF,input$edges)
          vcount(m_ng)})})
      output$m_edgeCount <- renderText({ecount(m_ng)})
      output$m_density <- renderText({graph.density(m_ng)})
      output$m_diameter <- renderText({diameter(m_ng)})
      output$m_clusters <- renderText({clusters(m_ng)$no})
    })
    
    ## Frequent words ##
    output$freqWords <- renderText({
      input$goButton
      isolate({
        withProgress(session, {
          setProgress(message = "Calculating, please wait",
                      detail = "This may take a few moments...")
          Sys.sleep(1)
          setProgress(detail = "Still working...")
          ##
          DF.corpus <- Corpus(VectorSource(DF$content))
          DF.corpus <- tm_map(DF.corpus, removePunctuation)
          DF.stopwords <- c(stopwords('english'), stopwords('dutch'))
          DF.corpus <- tm_map(DF.corpus, removeWords, DF.stopwords)
          DF.dtm <- TermDocumentMatrix(DF.corpus,control = list(wordLengths = c(3,10)))
          freqTerms <- findFreqTerms(DF.dtm, lowfreq=10) 
          setProgress(detail = "Almost there...")
          freqTerms #<- as.data.frame(freqTerms)
        })})
    })
    
    
    output$threats <- renderDataTable({
      
      sliderscore <- input$threat_scores
      
      input$threatButton
      isolate({
        withProgress(session, {
          
          threatFile<-input$threatFile
          print(threatFile)
          if(is.null(threatFile))
            return(NULL)
          setProgress(message = "Calculating, please wait",
                      detail = "This may take a few moments...")
          Sys.sleep(1)
          #showScores('www//dreigingslijst.txt')
          ##
          #tt <- scan('www/dreigingslijst.txt',what='character', comment.char=';')
          tt = scan(threatFile$datapath,what='character', comment.char=';')
          words <<- c(tt)
          tweet.scores <<- score.threats(DF$content, words, .progress='text')
          setProgress(detail = "Generating output ...")
          Sys.sleep(1)
          #dd <- as.data.frame(paste(DF$content,'|',DF$username,'|',DF$created_at)[tweet.scores == sliderscore])
          #dd <- as.data.frame(cbind(DF$content[tweet.scores == sliderscore],DF$username[tweet.scores == sliderscore],DF$created_at[tweet.scores == sliderscore]))
          #names(dd) <- 'Hits'
          #dd
          dd <<- DF[tweet.scores == sliderscore,]
          dd
          
          })
        })
        dd[, input$show_threatvars, drop = FALSE]
    })
    
  })
})