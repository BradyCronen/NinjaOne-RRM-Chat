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

The technician initiates the chat by running the script with their intial message being the custom parameter of the script in NinjaOne. 

<img width="796" height="523" alt="image" src="https://github.com/user-attachments/assets/1a0670cd-548b-4130-9b50-93af8f32eeb5" />

The user sees a clean chat window pop up on their desktop in their default browser.

<img width="2544" height="1189" alt="image" src="https://github.com/user-attachments/assets/9c73ec0a-b8a0-4533-a4a8-e640d9c6ff97" />

The user can toggle the interface language to Spanish and type their reply. The "Sending..." status appears as they type.

<img width="2538" height="1180" alt="image" src="https://github.com/user-attachments/assets/a3d66312-75e4-4700-9ab8-e36a328cdb18" />

The technician sees the user's reply in the NinjaOne Activity Log. The original message is preserved, and an English translation is automatically provided.

<img width="1456" height="867" alt="image" src="https://github.com/user-attachments/assets/0a56a627-f0fc-42a6-8a88-d75067d22d1f" />

If the technician wants to reply they must rerun the script with their reply being the custom parameter in Ninja One. Once sent the conversation continues, with the full history maintained for the user.

<img width="2541" height="1177" alt="image" src="https://github.com/user-attachments/assets/8687e5e2-6f1b-49ae-845e-fc5d9762b329" />

Each subsequent reply from the user is also logged and translated for the technician.

<img width="1456" height="865" alt="image" src="https://github.com/user-attachments/assets/cb7869c2-135a-4dee-afd2-a0b1c7ff1006" />

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
