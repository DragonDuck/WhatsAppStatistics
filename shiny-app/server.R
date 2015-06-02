library(shiny)
library(ggplot2)
library(reshape2)
library(qgraph)

# Create the minute-wise time series vectors for all users
startDate <- dateRange[1]
endDate <- dateRange[2]
timeSeriesByMinutes <- data.frame(Timestamp = seq(startDate, endDate, by = 60))
for(name in nameList) {
  ts.user <- table(chatDF$Name, chatDF$Timestamp)[name,]
  timeSeriesByMinutes <- cbind(timeSeriesByMinutes, 0)
  colnames(timeSeriesByMinutes) <- c(colnames(timeSeriesByMinutes)[1:length(colnames(timeSeriesByMinutes))-1],name)
  timeSeriesByMinutes[which(timeSeriesByMinutes$Timestamp %in% as.POSIXct(names(ts.user))), name] <- ts.user
}
# timespan <- as.numeric(difftime(endDate,startDate,units="mins"))
# timeSeriesByMinutes <- data.frame(deltaM = as.numeric(seq(0,timespan)), row.names = seq(0,timespan))
# for(name in nameList) {
#   # find positive values for each chatter
#   ts.user <- table(chatDF$Name, chatDF$Timestamp)[name,]
#   ts.user.names <- as.POSIXct(names(ts.user), format = "%Y-%m-%d %H:%M:%S")
#   ts.user.names <- sapply(ts.user.names, function(a){as.numeric(difftime(a,ts.user.names[1],units = "mins"))})
#   names(ts.user) <- ts.user.names
#   ts.user.df <- data.frame(deltaM = as.numeric(names(ts.user)), val = ts.user, row.names = NULL, stringsAsFactors = FALSE)
#   posVals <- ts.user.df[ ts.user.df$val > 0, ]$deltaM
#   # add column to ts
#   timeSeriesByMinutes <- cbind(timeSeriesByMinutes, 0)
#   colnames(timeSeriesByMinutes) <- c(colnames(timeSeriesByMinutes)[1:length(colnames(timeSeriesByMinutes))-1],name)
#   timeSeriesByMinutes[which(timeSeriesByMinutes$deltaM %in% posVals), name] <- ts.user[as.character(posVals)]
# }

# Smoothen the time series into a discrete density with a kernel width of 30 minutes
cutoff <- 15 # maximum +/- range for density estimation
timeSeriesSmooth <- apply(timeSeriesByMinutes[-1],2, function(tsCol) {
  sapply(seq_along(tsCol), function(x) {
    if(x <= cutoff) {
      return(mean(tsCol[1:(2*x)]))
    }
    if (x >= (length(tsCol) - cutoff)) {
      return(mean(tsCol[(x-cutoff):length(tsCol)]))
    }
    return(mean(tsCol[(x-15):(x+15)]))
  })
})
timeSeriesSmooth <- as.data.frame(timeSeriesSmooth)
timeSeriesSmooth <- cbind(Timestamp = timeSeriesByMinutes$Timestamp, timeSeriesSmooth)
# Normalization unnecessary for cor() function


shinyServer(function(input, output) {
  output$globalHistoPlot <- renderPlot({
    startDate <- input$globalHistoDate[1]
    endDate <- input$globalHistoDate[2]
    
    histDF <- chatDF[which(chatDF$Date >= startDate & chatDF$Date <= endDate),]
    histTable <- table(histDF$Name)
    histTable <- histTable[order(histTable, decreasing = TRUE)]
    histDF.ordered <- data.frame(name = names(histTable), postNum = histTable, row.names = NULL)
    histDF.ordered$name <- factor(histDF.ordered$name, levels = as.character(histDF.ordered$name))
    
    colors <- rainbow(length(histDF.ordered$name))
    bp <- ggplot(data = histDF.ordered, aes_string(x = "name", y = "postNum")) + 
      geom_bar(fill = colors, stat = "identity") + 
      theme(axis.text.x = element_text(angle = 90, hjust = 1, vjust = 0.5, size = 12, face = "bold")) + 
      xlab("") + ylab("Number of Posts") + theme(legend.position = "None", plot.title = element_text(lineheight=.8, face="bold", size=16), 
                                                 panel.grid.minor.x=element_blank(), panel.grid.major.x=element_blank()) + 
      ggtitle("Chat Frequency")
    return(bp)
  })
  
  output$postingTimesPlot <- renderPlot({
    startDate <- input$postingTimesDate[1]
    endDate <- input$postingTimesDate[2]
    name <- input$postingTimesNames
    
    hours <- NULL
    
    if(name == "Everyone") {
      hours <- as.POSIXlt(chatDF$Timestamp)$hour
    } else {
      hours <- as.POSIXlt(timeSeriesByMinutes$Timestamp[timeSeriesByMinutes[[name]] > 0])$hour
    }
    
    bp <- ggplot(data.frame(hours)) + geom_histogram(aes(x = hours), binwidth = 0.5) + 
      scale_x_continuous(breaks = 1:24) + xlab("Hour of the Day") + ylab("Number of Posts") + 
      ggtitle("User Posting Times")
    
    return(bp)
  })
  
  output$timeseriesPlot <- renderPlot({
    startDate <- input$timeseriesDate[1]
    endDate <- input$timeseriesDate[2]
    names <- input$timeseriesNames
    
    if(length(names) == 0) {
      errorMSG <- c("Please select at least one user to display")
      errorMSGdf <- data.frame(label = paste(errorMSG, collapse = "\n"))
      bp <- ggplot(data = errorMSGdf) + geom_text(aes(label = label, x = "", y = "", fontface = "bold")) + xlab("") + ylab("") + 
        theme(axis.ticks = element_blank(), panel.grid.minor=element_blank(), panel.grid.major=element_blank())
      return(bp)
    }
    
    tsDF <- chatDF[which(chatDF$Date >= startDate & chatDF$Date <= endDate),]
    timeSeries <- table(tsDF$Name, tsDF$Date)
    #if(nrow(timeSeries) == 1) {
    #  timeSeries <- matrix(timeSeries, dimnames = list(row.names(timeSeries), names(timeSeries)), nrow=1)
    #}
    timeSeriesDF <- data.frame(date = colnames(timeSeries), stringsAsFactors = FALSE, row.names = NULL)
    for(rname in row.names(timeSeries)) {
      timeSeriesDF <- cbind(timeSeriesDF, cumsum(timeSeries[rname,]))
    }
    row.names(timeSeriesDF) <- NULL
    names(timeSeriesDF) <- c("date",row.names(timeSeries))
    timeSeriesDF$date <- as.Date(timeSeriesDF$date)
    timeSeriesDF <- timeSeriesDF[,c("date",names)]
    
    df <- melt(timeSeriesDF, id="date")
    bp <- ggplot(data = df, aes_string(x = "date", y = "value", colour = "variable")) + 
      geom_line(size = 2) + theme(legend.title = element_blank()) + xlab("") + ylab("Number of Posts") + 
      theme(plot.title = element_text(lineheight=.8, face="bold", size=16)) + ggtitle("Time Series of Posts")
    return(bp)
  })
  
  output$correlationMatrixPlot <- renderPlot({
    startDate <- input$cmDate[1]
    endDate <- input$cmDate[2]
    users <- input$cmNames
    forceConstant <- input$cmPlotForce
    
    # Set up timeSeriesSmooth with starting dates and users
    modTS <- timeSeriesSmooth[which(timeSeriesSmooth$Timestamp >= as.POSIXct(startDate) & 
                                      timeSeriesSmooth$Timestamp <= as.POSIXct(endDate)), users][-1]
    correlationMatrix <- cor(modTS)
    diag(correlationMatrix) <- 0
    for(name in row.names(correlationMatrix)) {
      i <- which.max(correlationMatrix[name,])
      correlationMatrix[name,-i] <- 0
    }
    #return(correlationMatrix)
    gp <- qgraph(correlationMatrix, shape = "rectangle", vsize = 6, vsize2 = 3, color = "lightblue", 
                 labels = row.names(correlationMatrix), repulsion = forceConstant, bidirectional = TRUE)
    return(gp)
  })
})