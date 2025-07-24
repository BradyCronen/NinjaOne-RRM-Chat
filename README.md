NinjaOne Remote Chat Script

A non-interactive PowerShell script for NinjaOne that simulates a continuous chat session with an end-user. It creates a persistent chat log in the user's temporary directory, allowing for an ongoing conversation by simply re-running the script with a new message.



Features

Persistent Chat History: Maintains the full conversation history in a temporary log file for the duration of the session.



Bilingual Support:



Automatically translates technician messages from English to Spanish for the end-user.



Translates the end-user's replies from Spanish back to English for the technician.



Rich User Interface: Displays the chat in a clean, modern HTML interface with distinct bubbles for the technician and the user.



Batched Replies: To keep the NinjaOne activity log clean, the user's replies are intelligently batched. The script waits for the user to stop typing for 15 seconds before sending their entire response as a single message.



Session Management: The user can end the chat session by clicking the "Clear Chat" button, which will delete all temporary files and logs upon their next reply.



Timeout Functionality: The chat window automatically times out after 5 minutes of inactivity to prevent orphaned sessions.



Setup in NinjaOne

Follow these steps to add the chat script to your NinjaOne environment.



1. Create the Script

Navigate to the Administration section in NinjaOne.



Go to Library -> Scripts.



Click Create New Script.



2. Configure Script Settings

Use the following settings for the script:



Name: Remote Chat (or another descriptive name)



Description: Must rerun script to send another message to the end user.



Categories: Select an appropriate category (e.g., "Support Tools")



Language: PowerShell



Operating System: Windows



Architecture: All



Run As: Current Logged on User



3. Add the Script Code

Copy the entire contents of the NinjaOneRRMChat.ps1 script and paste it into the code editor field in NinjaOne.



4. Save the Script

Click Save to add the script to your library.



How to Use

Once the script is set up, you can initiate a chat with any user on a target device.



Find the device you want to start a chat with.



Click the Run button on the device's page.



Select Run Automation -> Script.



Search for and select the Remote Chat script you created.

In the Preset Parameter field, type the message you want to send to the user.

Click Run.

The script will execute on the remote machine, a notification will appear for the user, and the chat window will open.

When the user replies, their message will be captured and will appear in the device's Activity log in NinjaOne after a 15-second delay from their last keystroke. To continue the conversation, simply run the script again with your next message
