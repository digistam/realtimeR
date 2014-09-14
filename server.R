if (!require("shiny")) {
  install.packages("shiny", repos="http://cran.rstudio.com/") 
  library("shiny") 
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
        isolate(cat(tableName))
      })
      
    }) 
  }
    tableListbox()
    ##
    
    output$tweets <- renderDataTable({
      input$goButton
      isolate({
        q <- dbGetQuery(con, paste("SELECT * FROM ", tableName, "", sep=""))
        DF <<- as.data.frame(q)  
        
        #Recent <<- head(sort(DF$created_at,decreasing=T),n <- 5)
        #mn <- tapply(paste(DF$username,DF$followers),INDEX = paste(DF$username,'(',DF$followers,'followers )'),FUN=table)
        #tbl <- as.data.frame(as.table(mn))
        #names(tbl) <- c('Account','Frequency')
        #tbl <- tbl[order(tbl$Frequency, decreasing = T),]
        DF$created_at <- as.POSIXct(DF$created_at,format = "%Y-%m-%d %H:%M:%S")
        tbl <- DF
        #tbl$created_at <- as.POSIXct(tbl$created_at,format = "%Y-%m-%d %H:%M:%S")
        #tbl$Time <- as.POSIXct(DF$created_at,format = "%Y-%m-%d %H:%M:%S")
        #df <- tbl[order(as.POSIXct(tbl$created_at,format = "%Y-%m-%d %H:%M:%S"), decreasing = T),]
        df <- tbl[ order(tbl$created_at , decreasing = TRUE ),]
        #df <- tbl
        df#[order(df$created_at)]
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
        #df <- head(tbl,n=100)
        df <- tbl
      })
    })
    output$histfollow <- renderPlot({
      input$goButton
      isolate({
        hist(DF$followers)})
    })
  output$timeSeries <- renderPlot({
    input$goButton
    isolate({
    timeSeries <- as.POSIXct(DF$created_at,format = "%Y-%m-%d %H:%M:%S")
    plot(timeSeries, type="l")
    })
  })
    })
})