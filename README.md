# WhatsAppStatistics
R Shiny package to visualize user behaviour in WhatsApp group chats

## Usage Instructions

The usage of this software package is currently the very antithesis of user-friendly. In order to properly use it, you need the following software (in the newest versions) installed on your computer:

1. Python
2. R
3. RStudio
4. Shiny

In order to use your own chat file, you must first process it with the included python script (Chat.py):

1. Download the raw chat data (e.g. WhatsApp allows you to email yourself the chat data). Make sure to rename this file to chat.txt.
2. Run the included python script: python Chat.py and move the output file (chat_processed.txt) into the data folder of the Shiny app.
3. Open any of the *.R files in RStudio and run them as a Shiny app ("Run App" should appear in the top right of the code window. If not, simply source the file).
