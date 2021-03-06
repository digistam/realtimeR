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
             tags$link(rel = 'stylesheet', type = 'text/css', href = 'styles.css'),
             tags$style(type="text/css",
                        ".shiny-output-error {visibility: hidden; }",
                        ".shiny-output-before {visibility: hidden; }",
                        ".jslider { max-width: 600px; }"),
             fileInput('dbfile', 'load database file:'),
             #fileInput('threatFile', 'Select textfile', accept=c('text/ascii')),

             ## div
             selectizeInput('database_tables', 'select dataset:', choices = NULL),
             actionButton("goButton", "Go!"),
             HTML('<br />&nbsp;<br /><br />&nbsp;<br />'),
             
             fluidRow(
               checkboxGroupInput('show_vars', '',
                                  names(DF), selected = names(c(DF[3],DF[4],DF[5],DF[12],DF[13])), inline = T),
               dataTableOutput("tweets"),
               tags$head(tags$style("tfoot {display: table-header-group;}"))
             ),
             textOutput('tables')
    ),
    tabPanel("Influencers",
             tags$link(rel = 'stylesheet', type = 'text/css', href = 'styles.css'),
             p('dataset: '),
             textOutput('Inf_myKeyword'),
             p(),
             fluidRow(
               dataTableOutput(outputId="influence"),
               tags$head(tags$style("tfoot {display: table-header-group;}"))),
             textOutput('tables3')
    ),
    tabPanel("Network Graphs",
             tags$link(rel = 'stylesheet', type = 'text/css', href = 'styles.css'),
             sidebarPanel(
               downloadButton('downloadRtGraph', 'Download retweet network (Gephi)'),
               p(),
               downloadButton('downloadMnGraph', 'Download mention network (Gephi)'),
               p(),
               plotOutput('powerLaw'),
               p(),
               HTML('<p><b>Information:</b></p>'),
               HTML('<ul><li><a target=_blank href="http://www.danah.org/papers/TweetTweetRetweet.pdf">Tweet, Tweet, Retweet: Conversational Aspects of Retweeting on Twitter</a></li>'),
               HTML('<li><a target=_blank href="http://truthy.indiana.edu/site_media/pdfs/conover_icwsm2011_polarization.pdf">Political Polarization on Twitter</a></li>'),
               HTML('<li><a target=_blank href="http://journalistsresource.org/studies/politics/campaign-media/us-government-twitter-research">Twitter, politics and the public: Research roundup</a></li>'),
               HTML('<li><a target=_blank href="http://www.qcri.com/app/media/1900">Secular vs. Islamist Polarization in Egypt on Twitter</a></li>'),
               HTML('<li><a target=_blank href=http://www.youtube.com/watch?v=7LMnpM0p4cM>Gephi Modularity Tutorial</a></li></ul>')
               
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
                 p('')
                 #                  HTML('<p><b>Information:</b></p>'),
                 #                  HTML('<ul><li><a target=_blank href="http://www.danah.org/papers/TweetTweetRetweet.pdf">Tweet, Tweet, Retweet: Conversational Aspects of Retweeting on Twitter</a></li>'),
                 #                  HTML('<li><a target=_blank href="http://truthy.indiana.edu/site_media/pdfs/conover_icwsm2011_polarization.pdf">Political Polarization on Twitter</a></li>'),
                 #                  HTML('<li><a target=_blank href="http://journalistsresource.org/studies/politics/campaign-media/us-government-twitter-research">Twitter, politics and the public: Research roundup</a></li>'),
                 #                  HTML('<li><a target=_blank href="http://www.qcri.com/app/media/1900">Secular vs. Islamist Polarization in Egypt on Twitter</a></li></ul>')
               )
               
             )
             
    ),
     tabPanel("Textmining",
              tags$link(rel = 'stylesheet', type = 'text/css', href = 'styles.css'),
              p('dataset: '),
              textOutput('Words_myKeyword'),
              p(),
              HTML('Inspiration: <a href="https://etda.libraries.psu.edu/paper/21347/22336">Monitoring Human trafficking</a>'),
              h1('Textmining'),
              h2('Frequent terms'),   
              selectizeInput('freqTermsBox', 'select term:', choices = NULL),
              actionButton("freqTermsButton", "Go!"),
              fluidRow(
                dataTableOutput(outputId="assocWords")
              ),
              fluidRow(
                dataTableOutput(outputId="freqWords")
              )
     ),
    
#     tabPanel("TimeSeries",
#              
#              p('dataset: '),
#              
#              textOutput('Time_myKeyword'),
#              
#              fluidRow(
#                htmlOutput('timeSeries')),
#              p(),
#              sliderInput('timeSlider', 'Period in hours', 12, min =1, max = 24, step = 1),
#              checkboxInput("useSlider", "Unlimited period", FALSE),
#              verbatimTextOutput('sliderinfo')
#     ),

    tabPanel("Hashtags",
             tags$link(rel = 'stylesheet', type = 'text/css', href = 'styles.css'),
             p('dataset: '),
             #textOutput('Inf_myKeyword'),
             #        p(),
             fluidRow(
               dataTableOutput(outputId="hashtags")
             )),
#     tabPanel("Histogram",
#              p('dataset: '),
#              textOutput('Hist_myKeyword'),
#              p(),
#              htmlOutput('histfollow')
#     ),

    tabPanel("List matching",
             tags$link(rel = 'stylesheet', type = 'text/css', href = 'styles.css'),
             fileInput('threatFile', 'Select textfile', accept=c('text/ascii')),
             #actionButton("threatButton", "Go!"),
             
             fluidRow (
               h1('Matches'),
               checkboxGroupInput('show_threatvars', '',
                                  names(DF), selected = names(c(DF[3],DF[4],DF[5],DF[12],DF[13])), inline = T),
               sliderInput('threat_scores', 'score', 1, min = -5, max = 5, step = 1),
               dataTableOutput(outputId="threats"),
               plotOutput('threatHist')
               )
             ),
    tabPanel("Credits",
             tags$link(rel = 'stylesheet', type = 'text/css', href = 'styles.css'),
             p("Mark Stam"),
             HTML("<a target=_blank href=https://github.com/digistam/realtimeR>GitHub</a>"),
             # progressInit() must be called somewhere in the UI in order
             # for the progress UI to actually appear
             progressInit()
    )
    
  ))