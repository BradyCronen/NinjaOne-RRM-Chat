NinjaOne Remote Chat Script


A PowerShell script for NinjaOne that simulates a continuous chat session with an end-user. It creates a chat log in the end user's temporary directory that can be cleared by the user, allowing for an ongoing conversation by simply re-running the script with a new message.

***

Features

Persistent Chat History: Maintains the full conversation history in a temporary log file for the duration of the session.

Bilingual Support:

Automatically translates technician messages from English to Spanish for the end-user.

Translates the end-user's replies from Spanish back to English for the technician.

Rich User Interface: Displays the chat in a clean, modern HTML interface with distinct bubbles for the technician and the user.

Batched Replies: To keep the NinjaOne activity log clean, the user's replies are intelligently batched. The script waits for the user to stop typing for 15 seconds before sending their entire response as a single message.

Session Management: The user can end the chat session by clicking the "Clear Chat" button, which will delete all temporary files and logs upon their next reply.

Timeout Functionality: The chat window automatically times out after 5 minutes of inactivity to prevent orphaned sessions.

***

Demonstration
Here is a walkthrough of the script in action:

The technician initiates the chat by running the script with their message. The user sees a clean chat window pop up on their desktop in their default browser.

<img width="2536" height="1192" alt="IntialMessage" src="https://github.com/user-attachments/assets/0ae6aea4-b556-4046-842f-04e43038666c" />

The user can toggle the interface language to Spanish and type their reply. The "Sending..." status appears as they type.

<img width="2539" height="1174" alt="IntialReply" src="https://github.com/user-attachments/assets/f1828206-4442-47f8-bb1f-76e2e681b542" />

The technician sees the user's reply in the NinjaOne Activity Log. The original message is preserved, and an English translation is automatically provided.

<img width="1455" height="868" alt="TechniciansView" src="https://github.com/user-attachments/assets/869bf898-ebea-4ed7-9ef4-58c31e8b17d3" />

The conversation continues, with the full history maintained for the user.

<img width="2532" height="1180" alt="FinalReply" src="https://github.com/user-attachments/assets/73539822-994a-4dde-ac79-8ab18302f4bb" />

Each subsequent reply from the user is also logged and translated for the technician.

<img width="1453" height="865" alt="TechniciansFinalView" src="https://github.com/user-attachments/assets/d1ac57e5-32ef-4d8f-ab3b-8c460dca3e2d" />

***

Setup in NinjaOne RRM
Follow these steps to add the chat script to your NinjaOne environment.

1. Create the Script
Navigate to the Administration section in NinjaOne.

Go to Library -> Scripts.

Click Create New Script.

Select Create from file or paste the code into a blank one

2. Configure Script Settings
Use the following settings for the script:

Name: Remote Chat

Description: Must rerun script to send another message to the end user.

Categories: Select an appropriate category

Language: PowerShell

Operating System: Windows

Architecture: All

Run As: Current Logged on User

3. Add the Script Code
Copy the entire contents of the NinjaOneRRMChat.ps1 script and paste it into the code editor field in NinjaOne.

4. Save the Script
Click Save to add the script to your library.

***

How to Use
Once the script is set up, you can initiate a chat with any user on a target device.

Find the device you want to start a chat with.

Click the Run button on the device's page.

Select Run Automation -> Script.

Search for and select the Remote Chat script you created.

In the Preset Parameter field, type the message you want to send to the user.

Click Run.

The script will execute on the remote machine, a notification will appear for the user, and the chat window will open.

When the user replies, their message will be captured and will appear in the device's Activity log in NinjaOne after a 15-second delay from their last keystroke. To continue the conversation, simply run the script again with your next message.
