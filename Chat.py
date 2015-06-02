import codecs
import datetime
import re

class ChatEntry:

    def __init__(self, date, name, text):
        self.date = date
        self.name = name
        self.text = text

    def __repr__(self):
        returnString = u"({0}, {1}, {2})".format(str(self.date), self.name, self.text)
        return(returnString.encode("utf-8"))

    def appendText(self, newText):
        self.text = self.text + "\n" + newText

class Chat:

    months = {"Jan":1, "Feb":2, "Mar":3, "Apr":4,
              "May":5, "Jun":6, "Jul":7, "Aug":8,
              "Sep":9, "Oct":10, "Nov":11, "Dec":12}

    def __init__(self, fileName):
        self.fileName = fileName
        self.rawData = None
        self.cleanData = None
        with codecs.open(fileName,"r","utf-8") as file:
            self.rawData = file.read()
            self.processData()

    def __len__(self):
        return len(self.cleanData)

    def __getitem__(self, i):
        return self.cleanData[i]

    def processData(self):
        # TODO: Where is the year entry?

        # Output data format is a list of ChatEntry objects
        result = []
        lines = self.rawData.split("\n")
        for line in lines:
            # There are two possible formats for the beginning of the line.
            regexWithYear = "^[A-Z,a-z][A-Z,a-z][A-Z,a-z] [0-9][0-9]?, [0-9][0-9][0-9][0-9], [0-9][0-9][:][0-9][0-9] -"
            regexWithoutYear = "^[A-Z,a-z][A-Z,a-z][A-Z,a-z] [0-9][0-9]?, [0-9][0-9][:][0-9][0-9] -"

            # See which of the two styles match and split them along "," and spaces accordingly
            rWYMatch = re.match(regexWithYear,line)
            rWoYMatch = re.match(regexWithoutYear,line)

            year = None
            month = None
            day = None
            hour = None
            minute = None

            if rWYMatch or rWoYMatch:
                try:
                    textArray = None
                    if rWYMatch and not rWoYMatch:
                        textArray = rWYMatch.group(0)[:-2].split(",")
                    if not rWYMatch and rWoYMatch:
                        textArray = rWoYMatch.group(0)[:-2].split(",")

                    # Time
                    hourMin = textArray[-1].strip().split(":")
                    hour = int(hourMin[0]) # HOUR
                    minute = int(hourMin[1]) # MINUTE

                    # Date
                    if rWYMatch and not rWoYMatch:
                        year = int(textArray[1].strip()) # YEAR
                    else:
                        year = datetime.datetime.now().year # YEAR
                    monthDay = textArray[0].strip().split(" ")
                    day = int(monthDay[1]) # DAY
                    month = monthDay[0]
                    if month in Chat.months:
                        month = Chat.months[month] # MONTH
                    else:
                        if len(result) > 0:
                            result[-1].appendText(line)
                            continue

                except ValueError, e:
                    # Invalid formats means that the line belongs to the previous one
                    if len(result) > 0:
                        result[-1].appendText(line)
                        continue

            # if neither match, it's a continued text line: append it to the previous entry
            else:
                if len(result) > 0:
                    result[-1].appendText(line)
                    continue

            # If we've gotten this far, then this is clearly a new entry
            lineNoDate = line.split("-")[1:]
            lineNoDate = "-".join(lineNoDate).strip()
            # Ensure that this is an actual text line and not an administrative line
            # (e.g. X leaves the group)
            if lineNoDate.find(":") == -1:
                continue

            name = None
            text = None
            date = datetime.datetime(year, month, day, hour, minute)
            try:
                name = lineNoDate.split(":")[0].strip()
                # This removes the invisible unicode characters for unnamed numbers
                temp = name.split(u"\u202a")
                if len(temp) > 1:
                    temp = temp[1].split(u"\u202c")[0]
                    name = temp
                #name = Chat.namesDict[name]
                text = lineNoDate.split(":")[1:]
                text = ":".join(text).strip()
            except Exception, e:
                print("Something went wrong with name extraction in line: \n" + line)

            entry = ChatEntry(date, name, text)

            # Check if the previous entry had the same author and is in quick succession
            if len(result) > 0:
                pEntry = result[-1]
                if name == pEntry.name and abs((date-pEntry.date).total_seconds()) < 180:
                    result[-1].appendText(text)
                    continue

            result.append(entry)
        self.cleanData = result

    def saveProcessedData(self):
        # Save processed ("clean") data
        data = self.cleanData
        fileName = self.fileName.split(".")
        fileName = ".".join(fileName[0:-1]) + "_processed.txt"
        with codecs.open(fileName,"w","utf-8") as file:
            for entry in self.cleanData:
                date = datetime.date(entry.date.year, entry.date.month, entry.date.day)
                time = str(entry.date.hour) + ":" + str(entry.date.minute) + ":00"
                file.write(str(date) + "\t" + str(time) + "\t" + str(entry.name) + "\t" + repr(entry.text) + "\n")

chat = Chat("chat.txt")
chat.processData()
chat.saveProcessedData()