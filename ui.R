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
      checkboxGroupInput('show_vars', 'Columns in dataframe to show:',
                         names(DF), selected = names(c(DF[3],DF[10],DF[11])), inline = T),
      dataTableOutput("tweets"),
      tags$head(tags$style("tfoot {display: table-header-group;}"))
    ),
  textOutput('tables')
  ),
   
  
  #tabPanel("Most recent",
  #         HTML('<b>UTC tijd (GMT -2)</b>'),
  #         fluidRow(
  #           dataTableOutput(outputId="recent"),
  #           tags$head(tags$style("tfoot {display: table-header-group;}")))),
  tabPanel("TimeSeries",
           fluidRow(
             plotOutput('timeSeries', heigh=800, width=800))),
  tabPanel("Influence",
           HTML('<b>Influence</b>'),
           fluidRow(
             dataTableOutput(outputId="influence"),
             tags$head(tags$style("tfoot {display: table-header-group;}")))),
  tabPanel("Histogram",
    p('Histogram'),
    plotOutput('histfollow', height=800, width=800)),
  tabPanel("Credits",
    p("Mark Stam"))
))