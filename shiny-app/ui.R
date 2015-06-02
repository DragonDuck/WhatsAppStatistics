library(shiny)

shinyUI(navbarPage(title = "WhatsApp Chat Stat",
                   tabPanel("Global Activity",
                            sidebarLayout(
                              sidebarPanel(
                                dateRangeInput(inputId = "globalHistoDate", label = "Select timeframe for histogram data", 
                                               start = dateRange[1], end = dateRange[2], min = dateRange[1], max = dateRange[2],
                                               weekstart = 1, format="M dd, yyyy")
                              ),
                              mainPanel(
                                plotOutput(outputId = "globalHistoPlot")
                              )
                            )),
                   tabPanel("Posting Times",
                            sidebarLayout(
                              sidebarPanel(
                                dateRangeInput(inputId = "postingTimesDate", label = "Select timeframe for histogram data", 
                                               start = dateRange[1], end = dateRange[2], min = dateRange[1], max = dateRange[2],
                                               weekstart = 1, format="M dd, yyyy"),
                                selectizeInput(inputId = "postingTimesNames", label = "Select users to display", choices = c("Everyone",nameList), multiple = FALSE)
                              ),
                              mainPanel(
                                plotOutput(outputId = "postingTimesPlot")
                              )
                            )),                                
                   tabPanel("Time Series",
                            sidebarLayout(
                              sidebarPanel(
                                dateRangeInput(inputId = "timeseriesDate", label = "Select timeframe for time series data", 
                                               start = dateRange[1], end = dateRange[2], min = dateRange[1], max = dateRange[2],
                                               weekstart = 1, format="M dd, yyyy"),
                                selectizeInput(inputId = "timeseriesNames", label = "Select users to display", choices = nameList, multiple = TRUE)
                              ),
                              mainPanel(
                                plotOutput(outputId = "timeseriesPlot")
                                #textOutput(outputId = "textOut")
                              )
                            )),
                   tabPanel("Network",
                            sidebarLayout(
                              sidebarPanel(
                                dateRangeInput(inputId = "cmDate", label = "Select timeframe for participant network data", 
                                               start = dateRange[1], end = dateRange[2], min = dateRange[1], max = dateRange[2],
                                               weekstart = 1, format="M dd, yyyy"),
                                selectizeInput(inputId = "cmNames", label = "Select users to display", choices = nameList, multiple = TRUE, selected = nameList),
                                sliderInput(inputId = "cmPlotForce",label = "Force constant for graph spacing", 
                                            min = 0, max = 2, value = 0.75, step = 0.05)
                              ),
                              mainPanel(
                                plotOutput(outputId = "correlationMatrixPlot")
                                #textOutput(outputId = "textOut")
                              )
                            ))
))