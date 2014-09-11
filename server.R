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
    output$values <- renderPrint({
      input$goButton
      isolate(input$database_tables)
    })
    
    q <- dbGetQuery(con, paste("SELECT * FROM ", dbtbl[2], "", sep=""))
    DF <<- as.data.frame(q)
    mn <- tapply(DF$username,INDEX = DF$username,FUN=table)
    tbl <- as.data.frame(as.table(mn))
    tbl <- tbl[order(tbl$Freq, decreasing = T),]
    df <- head(tbl,n=10)
    output$tweets <- renderDataTable({
      input$goButton
      isolate(
        df
        )
      })
    
    })
})