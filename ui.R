if (!require("shiny")) {
  install.packages("shiny", repos="http://cran.rstudio.com/") 
  library("shiny") 
}
shinyUI(navbarPage(
  
  "realtimeR 0.1", id="nav",
  
  tabPanel("Dataset",
           tags$style(type="text/css",
                      ".shiny-output-error {visibility: hidden; }",
                      ".shiny-output-before {visibility: hidden; }"),
    fileInput('dbfile', 'load database file:'),

    ## div
    selectizeInput('database_tables', 'select dataset:', choices = NULL),
    actionButton("goButton", "Go!"),
    HTML('<br />&nbsp;<br /><br />&nbsp;<br />'),
    #p('Dataset'),
    
  fluidRow(
      dataTableOutput(outputId="tweets")
    ),
  textOutput('tables')
  ),
   
  
  tabPanel("Meest recent",
           HTML('<b>UTC tijd (GMT -2)</b>'),
           fluidRow(
             dataTableOutput(outputId="recent"))),
  tabPanel("Histogram",
    p('Histogram'),
    plotOutput('histfollow', height=600, width=600)),
  tabPanel("Credits",
    p("Mark Stam"))
))