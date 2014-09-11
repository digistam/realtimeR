if (!require("shiny")) {
  install.packages("shiny", repos="http://cran.rstudio.com/") 
  library("shiny") 
}
shinyUI(navbarPage("realtimeR 0.1", id="nav",
  tabPanel("Dataset",
           
    fileInput('dbfile', 'Select db file'),
    p('Dataset'),
    selectizeInput('database_tables', 'database_tables', choices = NULL),
    verbatimTextOutput('values'),
    actionButton("goButton", "Go!"),
    fluidRow(
      dataTableOutput(outputId="tweets")
    )),
  tabPanel("Histogram",
    p('Histogram')),
  tabPanel("Credits",
    p("Mark Stam"))
))