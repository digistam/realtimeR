if (!require("shiny")) {
  install.packages("shiny", repos="http://cran.rstudio.com/") 
  library("shiny") 
}
if (!require("googleVis")) {
  install.packages("googleVis", repos="http://cran.rstudio.com/") 
  library("googleVis") 
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
        isolate(cat(tableName))
      })
      
    }) 
  }
    tableListbox()

    output$tweets <- renderDataTable({
      input$goButton
      isolate({
        q <- dbGetQuery(con, paste("SELECT * FROM ", tableName, "", sep=""))
        DF <<- as.data.frame(q)  
        DF$created_at <- as.POSIXct(DF$created_at,format = "%Y-%m-%d %H:%M:%S")
        tbl <- DF
        df <- tbl[ order(tbl$created_at , decreasing = TRUE ),]
        df
        })
      DF[, input$show_vars, drop = FALSE]
    })
    output$influence <- renderDataTable({
      input$goButton
      isolate({
        mn <- tapply(paste(DF$username,DF$followers),INDEX = paste(DF$username,'(',DF$followers,'followers )'),FUN=table)
        tbl <- as.data.frame(as.table(mn))
        names(tbl) <- c('Account','Frequency')
        tbl <- tbl[order(tbl$Frequency, decreasing = T),]
        df <- tbl
      })
    })
    output$histfollow <- renderGvis({
      input$goButton
      isolate({
        dfFoll <- as.data.frame(DF$followers)
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
      })

  bias <- input$nodes
  bias <- bias * 3600
  output$sliderinfo <- renderText(bias)
  output$timeSeries <- renderGvis({
    input$goButton
    isolate({
      ttt <- as.POSIXct(DF$created_at,format = "%Y-%m-%d %H:%M:%S") 
      uuu <- Sys.time() - bias
      vvv <- ttt[ttt > uuu]
      t2 <- strptime(vvv, format="%Y-%m-%d %H:%M")
      t2$min <- round(t2$min, -1)
      ddd <- as.character(t2)
      eee <- tapply(ddd,INDEX = ddd,FUN=table)
      fff <- as.data.frame(as.table(eee))
      names(fff) <- c('Account','Frequency')
      df <- data.frame(a=fff$Account, tweets=fff$Frequency)
      gvisLineChart(df, xvar="a", yvar=c("tweets"),options=list(
        title="Trendline",
        fontSize = 10))
    })    
  })
})
})