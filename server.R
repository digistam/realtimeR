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
          output$Hist_myKeyword <- renderPrint(tableName)
          output$Rt_myKeyword <- renderPrint(tableName)
          output$Words_myKeyword <- renderPrint(tableName)
          #isolate(cat(tableName))
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
        DF$followers <- as.numeric(DF$followers)
        DF <<- DF
        DF
      })
      #rm(list = c("t2"))
      DF[, input$show_vars, drop = FALSE]
    })
    
    output$influence <- renderDataTable({
      #input$goButton
      #isolate({
        withProgress(session, {
          setProgress(message = "Calculating, please wait",
                      detail = "This may take a few moments...")
          Sys.sleep(1)
          retweets(DF,input$edges)
#           mn <- tapply(paste(DF$username,DF$followers),INDEX = paste(DF$username,'|',DF$followers),FUN=table)
#           tbl <- as.data.frame(as.table(mn))
#           names(tbl) <- c('name','freq')
#           tbl_split <- data.frame(do.call('rbind', strsplit(as.character(tbl$name),'|',fixed=TRUE)))
#           tbl <- cbind(as.numeric(tbl$freq),tbl_split)
#           names(tbl) <- c('Frequency','Account','Followers')

dg <- degree(ng)
dg <- as.data.frame(as.table(dg))
bt <- betweenness(ng)
bt <- as.data.frame(as.table(bt))
user <- as.data.frame(cbind(DF$username,as.integer(DF$followers)))
names(dg) <- c('Username','Retweeted')
names(bt) <- c('Username','Betweenness')
names(user) <- c('Username','Followers')
#merge(user, dg, by = 'name')
#user <- merge(user, dg, by = 'name',incomparables = NULL, all = TRUE)
setProgress(detail = "Still working...")
Sys.sleep(1)
dd <- merge(user, dg, by = 'Username',incomparables = NULL, all.x = TRUE)
dd <- merge(dd, bt, by = 'Username',incomparables = NULL, all.x = TRUE)
dd[is.na(dd)] <- 0
ddd <- cbind(dd,DF$followers)
cc <- table(unlist(paste(ddd[,1],ddd[,2],ddd[,3],ddd[,4])))
cc <- as.data.frame(as.table(cc))
setProgress(detail = "Still working...")
Sys.sleep(1)
dd <- data.frame(do.call('rbind', strsplit(as.character(cc$Var1),' ',fixed=TRUE)))
tbl <- cbind(as.numeric(cc$Freq),dd)
names(tbl) <- c('Frequency','Account','Followers','Retweeted','Betweenness')
tbl$Followers <- as.numeric.factor(tbl$Followers)
tbl$Retweeted <- as.numeric.factor(tbl$Retweeted)
tbl$Betweenness <- as.numeric.factor(tbl$Betweenness)
#tbl$Followers <- as.numeric(tbl$Followers)
tbl <- tbl[order(tbl$Frequency, decreasing = T),]
setProgress(detail = "Generating output...")
Sys.sleep(1)
df <- tbl

       # })
})
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

    
    ### alle gevonden created_at tijden eenmaling rounden en daar een dataset van opbouwen
    ### vervolgens kan uit deze dataset geput worden voor de tijdlijn, hierdoor snel resultaat
    ### in plaats van telkens opnieuw berekenen
    ###
    ### t2 <- strptime(DF$created_at, format="%Y-%m-%d %H:%M")
    ### t2$min <- round(t2$min, -1)
    ### resultaat: t2 is een dataset met alle afgeronde tijden uit DF$created_at
    ### deze moet worden vergeleken met de slider offset:
    ### now <- strptime(Sys.time(),format="%Y-%m-%d %H:%M")
    ### now$min <- round(now$min,-1)
    ### bias <- input$timeSlider
    ### offset <- now - bias
    ### t2[offset] geeft als resultaat het aantal tweets binnen de gezochte tijdspanne
    ### t2table <- as.data.frame(as.table((tapply(as.character(t2[offset]),INDEX = as.character(t2[offset]),FUN=table))))
    ### names(t2table) <- c('Times','Frequency')
    

    #roundTimes()
    
    sliderTimeValues <- reactive({
      now <- strptime(Sys.time(),format="%Y-%m-%d %H:%M")
      now$min <- round(now$min,-1)
      bias <- input$timeSlider * 3600
      offset <- now - bias
      t2table <<- as.data.frame(as.table((tapply(as.character(t2[t2 > offset]),INDEX = as.character(t2[t2 > offset]),FUN=table))))
      names(t2table) <- c('Times','Frequency')
      timeLine <- data.frame(a=t2table$Times, tweets=t2table$Frequency)
      timeLine <<- timeLine
    })
    output$timeSeries <- renderGvis({
      if(!exists("t2")) {
      roundTimes()
      }
      if (input$useSlider != TRUE) {
        sliderTimeValues()
        } else { 
          t2table <- as.data.frame(as.table((tapply(as.character(t2),INDEX = as.character(t2),FUN=table))))
          names(t2table) <- c('Times','Frequency')
          timeLine <- data.frame(a=t2table$Times, tweets=t2table$Frequency)
        }
      gvisLineChart(timeLine, xvar="a", yvar=c("tweets"),options=list(
        title="Trendline",
        fontSize = 10))
    })

output$threatHist <- renderPlot({
  
  ##
  set.seed(123)
  barplot(table(score))
  
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
          output$clustercoeff <- renderText({transitivity(ng)})
        })
      })
      
      ## mention network
      output$m_nodeCount <- renderText({
        input$goButton
        isolate({
          m_retweets(DF,input$edges)
          vcount(m_ng)})})
      #write.graph(m_ng,'.\\www\\mention.graphml',format <- 'graphml')
      output$m_edgeCount <- renderText({ecount(m_ng)})
      output$m_density <- renderText({graph.density(m_ng)})
      output$m_diameter <- renderText({diameter(m_ng)})
      output$m_clusters <- renderText({clusters(m_ng)$no})
      output$m_clustercoeff <- renderText({transitivity(m_ng)})
      output$downloadRtGraph = downloadHandler(
        filename = "retweetnetwork.graphml",
        content = function(file) {
          write.graph(ng, file, format <- 'graphml')
        })
      output$downloadMnGraph = downloadHandler(
        filename = "mentionnetwork.graphml",
        content = function(file) {
          write.graph(ng, file, format <- 'graphml')
        })
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
          DF.dtm <- TermDocumentMatrix(DF.corpus,control = list(wordLengths = c(2,10)))
          freqTerms <- findFreqTerms(DF.dtm, lowfreq=10) 
          setProgress(detail = "Almost there...")
          freqTerms #<- as.data.frame(freqTerms)
        })})
    })
    
    threatFile<-input$threatFile
    print(threatFile)
    if(is.null(threatFile))
      return(NULL)
    withProgress(session, {
      setProgress(message = "Calculating, please wait",
                  detail = "This may take a few moments...")
      Sys.sleep(1)
        showScores(threatFile$datapath,'www/minwords.txt') 
      })
  sliderThreatValues <- reactive({
    dd <<- DF[score == input$threat_scores,]
  })
    output$threats <- renderDataTable({
        withProgress(session, {
           setProgress(message = "Calculating, please wait",
                       detail = "This may take a few moments...")
           Sys.sleep(1)

          sliderThreatValues()
          dd
    })
      dd[, input$show_threatvars, drop = FALSE]
    })

  
  })
})