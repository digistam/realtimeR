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
    
  fluidRow(
    checkboxGroupInput('show_vars', 'Columns in dataframe to show:',
                       names(DF), selected = names(c(DF[3],DF[10],DF[11])), inline = T),
      dataTableOutput("tweets"),
      tags$head(tags$style("tfoot {display: table-header-group;}"))
    ),
  textOutput('tables')
  ),
   
  tabPanel("TimeSeries",
           p('dataset: '),

           textOutput('Time_myKeyword'),
           
           fluidRow(
             htmlOutput('timeSeries')),
           p(),
           sliderInput('nodes', 'select period in hours', 6, min =0, max = 12, step = 1),
           verbatimTextOutput('sliderinfo')
           ),
  tabPanel("Influence",
           p('dataset: '),
           textOutput('Inf_myKeyword'),
           p(),
           fluidRow(
             dataTableOutput(outputId="influence"),
             tags$head(tags$style("tfoot {display: table-header-group;}"))),
           textOutput('tables3')
           ),
  tabPanel("Histogram",
           p('dataset: '),
           textOutput('Hist_myKeyword'),
           p(),
    htmlOutput('histfollow')),
  tabPanel("Credits",
    p("Mark Stam"))
))