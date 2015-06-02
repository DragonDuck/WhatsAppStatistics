# Load processed chat data
chatDF <- read.table(file = "data/chat_processed.txt", sep = "\t", quote = "", 
                     colClasses = c("Date","character","character","character"))
names(chatDF) <- c("Date","Time","Name","Text")

# Add timestamp column to chatDF
timeStamp <- as.POSIXct(paste(chatDF$Date, chatDF$Time), format = "%Y-%m-%d %H:%M:%S")
chatDF[["Timestamp"]] <- timeStamp

# Extract the names of all participants
nameList <- names(table(chatDF$Name))

# This is a vector consisting of the first date and last date in a given data set
dateRange = c(chatDF$Timestamp[1], chatDF$Timestamp[length(chatDF$Timestamp)])