if (!require("shiny")) {
  install.packages("shiny", repos="http://cran.rstudio.com/") 
  library("shiny") 
}
if (!require(devtools)) {
  install.packages("devtools")
  devtools::install_github("rstudio/shiny-incubator")
}
library(shinyIncubator)

shinyUI(
  
  navbarPage(
    
    "realtimeR 0.1", id="nav",
    
    tabPanel("Dataset",
             tags$style(type="text/css",
                        ".shiny-output-error {visibility: hidden; }",
                        ".shiny-output-before {visibility: hidden; }",
                        ".jslider { max-width: 600px; }"),
             p('To Do: woord associaties, sentiment analyse, graphml export, excel export'),
             fileInput('dbfile', 'load database file:'),
             #fileInput('threatFile', 'Select textfile', accept=c('text/ascii')),

             ## div
             selectizeInput('database_tables', 'select dataset:', choices = NULL),
             actionButton("goButton", "Go!"),
             HTML('<br />&nbsp;<br /><br />&nbsp;<br />'),
             
             fluidRow(
               checkboxGroupInput('show_vars', '',
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
             sliderInput('timeSlider', 'Period in hours', 12, min =1, max = 24, step = 1),
             checkboxInput("useSlider", "Unlimited period", FALSE),
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
    tabPanel("Hashtags",
             p('dataset: '),
             #textOutput('Inf_myKeyword'),
             #        p(),
             fluidRow(
               dataTableOutput(outputId="hashtags")
             )),
    tabPanel("Words",
             p('dataset: '),
             textOutput('Words_myKeyword'),
             p(),
             h1('Frequent words'),
             verbatimTextOutput('freqWords')
    ),
    tabPanel("Histogram",
             p('dataset: '),
             textOutput('Hist_myKeyword'),
             p(),
             htmlOutput('histfollow')
    ),
    tabPanel("Networks",
              sidebarPanel(
                downloadButton('downloadRtGraph', 'Download retweet network (Gephi)'),
                p(),
                downloadButton('downloadMnGraph', 'Download mention network (Gephi)')
              ),
              mainPanel(
               fluidRow (
                 h1('Retweet network'),
                 p('Unique nodes in graph: '),
                 verbatimTextOutput("nodeCount"),
                 p('Unique edges in graph: '),
                 verbatimTextOutput("edgeCount"),
                 p('Graph density: '),
                 verbatimTextOutput("density"),
                 p('Connected components: '),
                 verbatimTextOutput("clusters"),
                 p('Clustering coefficient'),
                 verbatimTextOutput("clustercoeff"),
                 p('Largest diameter: '),
                 verbatimTextOutput("diameter")
                 
               ),
               fluidRow (
                 
                 h1('Mention network'),
                 p('Unique nodes in graph: '),
                 verbatimTextOutput("m_nodeCount"),
                 p('Unique edges in graph: '),
                 verbatimTextOutput("m_edgeCount"),
                 p('Graph density: '),
                 verbatimTextOutput("m_density"),
                 p('Connected components: '),
                 verbatimTextOutput("m_clusters"),
                 p('Clustering coefficient'),
                 verbatimTextOutput("m_clustercoeff"),
                 p('Largest diameter: '),
                 verbatimTextOutput("m_diameter"),
                 p('zorg voor mogelijkheid export graphml bestanden'),
                 p('case studies: http://www.danah.org/papers/TweetTweetRetweet.pdf, http://truthy.indiana.edu/site_media/pdfs/conover_icwsm2011_polarization.pdf, http://journalistsresource.org/studies/politics/campaign-media/us-government-twitter-research')
                )
            )

    ),
    tabPanel("Test",
             fileInput('threatFile', 'Select textfile', accept=c('text/ascii')),
             #actionButton("threatButton", "Go!"),
             
             fluidRow (
               h1('Threat scores'),
               checkboxGroupInput('show_threatvars', '',
                                  names(DF), selected = names(c(DF[3],DF[10],DF[11])), inline = T),
               sliderInput('threat_scores', 'Dreigingsscore', 1, min = -5, max = 5, step = 1),
               dataTableOutput(outputId="threats"),
               plotOutput('threatHist')
               )
             ),
    tabPanel("Credits",
             p("Mark Stam"),
             HTML("<a target=_blank href=https://github.com/digistam/realtimeR>GitHub</a>"),
             # progressInit() must be called somewhere in the UI in order
             # for the progress UI to actually appear
             progressInit()
    )
    
  ))