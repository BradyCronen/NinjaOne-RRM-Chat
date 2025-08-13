<#
.SYNOPSIS
    A non-interactive script for an RMM platform that simulates a continuous chat using a persistent temporary log file.
.DESCRIPTION
    This script checks for a chatlog.txt in the user's temp folder. If it exists, it appends the new
    technician message and displays the full history. The user can click "Clear Chat" to end the session
    after their next reply. All messages are translated, and the UI is fully featured.
.PARAMETER
    The first argument passed to the script is treated as the message for the user.

#>

# --- Script Parameters ---
if ($args.Count -eq 0) {
    # Provide a simple, clear error message for the technician in the RMM output.
    Write-Output "Error: The message parameter was left blank. Please ensure you type a message before running the script."
    # Formally throw an error so the script action correctly reports as 'Failed'.
    Write-Error "Script failed: No message was provided as a parameter."
    exit 1
}
$TechMessage = $args -join ' '


# --- Script Configuration ---
$tempPath = [System.IO.Path]::GetTempPath()
$logFile = Join-Path $tempPath "chatlog.txt"
$desktopPath = [Environment]::GetFolderPath("Desktop")
$downloadsPath = [Environment]::ExpandEnvironmentVariables((Get-ItemProperty -Path 'Registry::HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders').'{374DE290-123F-4565-9164-39C4925E467B}')
$htmlFile = Join-Path $desktopPath "IT_Support_Message.html"
$replyFileName = "IT_Support_Reply.txt"
$cleanupSignalFile = Join-Path $downloadsPath "Clear_Chat_Log.signal"

# --- Functions ---

function Cleanup-SessionFiles {
    param([bool]$FinalCleanup = $false)
    Write-Host "Cleaning up session files..."
    
    # Always clean up the temporary HTML and Reply files from the current session
    if (Test-Path $htmlFile) { Remove-Item $htmlFile -Force -ErrorAction SilentlyContinue }
    if (Test-Path $downloadsPath) {
        Get-ChildItem -Path $downloadsPath -Filter "IT_Support_Reply*" -ErrorAction SilentlyContinue | ForEach-Object {
            if ($_.Name -like "IT_Support_Reply*.txt" -or $_.Name -like "IT_Support_Reply*.txt.crdownload") {
                Remove-Item -Path $_.FullName -Force -ErrorAction SilentlyContinue
            }
        }
    }

    # Only perform the FINAL cleanup of the persistent log and signal files if requested
    if ($FinalCleanup) {
        if (Test-Path $logFile) {
            Write-Host "Performing final cleanup of chat log..."
            Remove-Item $logFile -Force -ErrorAction SilentlyContinue
        }
        if (Test-Path $cleanupSignalFile) {
            Write-Host "Cleaning up session signal file..."
            Remove-Item $cleanupSignalFile -Force -ErrorAction SilentlyContinue
        }
    }
    Write-Host "Cleanup complete."
}

function Parse-ChatLog {
    param([string[]]$LogLines)
    $history = [System.Collections.ArrayList]::new()
    $currentMessage = ""
    $currentSender = ""

    foreach ($line in $LogLines) {
        if ($line.StartsWith("Technician:")) {
            if ($currentMessage) { $history.Add([PSCustomObject]@{ Sender = $currentSender; Content = $currentMessage.Trim() }) | Out-Null }
            $currentSender = "Technician"
            $currentMessage = $line.Substring("Technician:".Length).Trim()
        } elseif ($line.StartsWith("User:")) {
            if ($currentMessage) { $history.Add([PSCustomObject]@{ Sender = $currentSender; Content = $currentMessage.Trim() }) | Out-Null }
            $currentSender = "User"
            $currentMessage = $line.Substring("User:".Length).Trim()
        } else {
            $currentMessage += "`n" + $line
        }
    }
    if ($currentMessage) { $history.Add([PSCustomObject]@{ Sender = $currentSender; Content = $currentMessage.Trim() }) | Out-Null }
    return $history
}

function Update-ChatHtml {
    param(
        [System.Collections.ArrayList]$ChatHistory,
        [string]$HtmlFilePath
    )
    
    $chatBubbles = foreach ($message in $ChatHistory) {
        $safeContent = $message.Content -replace "'", "&#39;" -replace '"', "&quot;"
        $safeSpanishContent = $message.SpanishContent -replace "'", "&#39;" -replace '"', "&quot;"
        
        if ($message.Sender -eq 'Technician') {
            @"
    <div class="max-w-md p-4 rounded-lg shadow chat-bubble-tech">
        <p class="text-xs font-bold mb-1 text-green-400 tech-label">Technician</p>
        <p class="text-sm whitespace-pre-wrap tech-message-content" data-en="$safeContent" data-es="$safeSpanishContent">$safeContent</p>
    </div>
"@
        } else {
            @"
    <div class="max-w-md p-4 rounded-lg shadow chat-bubble-user self-end">
        <p class="text-sm whitespace-pre-wrap">$safeContent</p>
    </div>
"@
        }
    }

    $htmlTemplate = @"
<!DOCTYPE html>
<html lang="en" class="h-full bg-zinc-900">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Message from IT Support</title>
    <script src="https://cdn.tailwindcss.com"></script>
    <style>
        .chat-bubble-tech { background-color: #3f3f46; /* zinc-700 */ color: #e4e4e7; /* zinc-200 */ }
        .chat-bubble-user { background-color: #16A34A; /* green-600 */ color: #FFFFFF; }
        @keyframes dim {
            0%, 100% { opacity: 1; }
            50% { opacity: 0.5; }
        }
        .dimming-text {
            animation: dim 1.5s ease-in-out infinite;
        }
    </style>
</head>
<body class="h-full flex flex-col font-sans bg-zinc-900 text-zinc-200">
    <div class="bg-zinc-800 text-zinc-200 p-4 flex items-center justify-between shadow-md border-b border-zinc-700">
        <div class="flex-1 flex items-center space-x-2">
            <button id="lang-toggle" class="px-3 py-1.5 bg-zinc-700 text-zinc-200 font-semibold rounded-md hover:bg-zinc-600 focus:outline-none focus:ring-2 focus:ring-white focus:ring-offset-2 focus:ring-offset-zinc-800 transition shadow text-sm inline-flex items-center">
                <svg xmlns="http://www.w3.org/2000/svg" class="w-5 h-5 mr-1.5" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                    <path d="m5 8 6 6"/><path d="m4 14 6-6 2-3"/><path d="M2 5h12"/><path d="M7 2h1"/><path d="m22 22-5-10-5 10"/><path d="M14 18h6"/>
                </svg>
                <span id="lang-toggle-text">Español</span>
            </button>
            <button id="clear-chat" class="px-3 py-1.5 bg-zinc-700 text-zinc-200 font-semibold rounded-md hover:bg-zinc-600 focus:outline-none focus:ring-2 focus:ring-white focus:ring-offset-2 focus:ring-offset-zinc-800 transition shadow text-sm inline-flex items-center">
                <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor" class="w-4 h-4 mr-1.5"><path stroke-linecap="round" stroke-linejoin="round" d="M14.74 9l-.346 9m-4.788 0L9.26 9m9.968-3.21c.342.052.682.107 1.022.166m-1.022-.165L18.16 19.673a2.25 2.25 0 01-2.244 2.077H8.084a2.25 2.25 0 01-2.244-2.077L4.772 5.79m14.456 0a48.108 48.108 0 00-3.478-.397m-12 .562c.34-.059.68-.114 1.022-.165m0 0a48.11 48.11 0 013.478-.397m7.5 0v-.916c0-1.18-.91-2.124-2.09-2.201a51.964 51.964 0 00-3.32 0c-1.18.077-2.09.921-2.09 2.201v.916m7.5 0a48.667 48.667 0 00-7.5 0" /></svg>
                <span id="clear-chat-text">Clear Chat</span>
            </button>
        </div>
        <div class="flex-1 text-center">
            <h1 id="main-header" class="text-xl font-bold">IT Support Chat</h1>
        </div>
        <div class="flex-1"></div>
    </div>
    
    <div id="chat-window" class="flex-1 p-4 sm:p-6 overflow-y-auto flex flex-col gap-4">
        $($chatBubbles -join "`n")
    </div>

    <div class="p-4 bg-zinc-800 border-t border-zinc-700">
        <div class="flex items-center space-x-3">
            <input type="text" id="reply-input" placeholder="Type your reply here..." class="flex-1 w-full px-4 py-2 bg-zinc-700 border border-zinc-600 rounded-full text-zinc-200 placeholder-zinc-400 focus:outline-none focus:ring-2 focus:ring-green-500 focus:border-green-500 transition">
            <button id="send-button" class="inline-flex items-center px-6 py-2 bg-green-600 text-white font-semibold rounded-full hover:bg-green-700 focus:outline-none focus:ring-2 focus:ring-green-500 focus:ring-offset-2 focus:ring-offset-zinc-800 transition shadow">
                <span id="send-button-text">Send</span>
                <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor" class="w-5 h-5 ml-2">
                    <path stroke-linecap="round" stroke-linejoin="round" d="M6 12 3.269 3.125A59.769 59.769 0 0 1 21.485 12 59.768 59.768 0 0 1 3.27 20.875L5.999 12Zm0 0h7.5" />
                </svg>
            </button>
        </div>
        <div id="translation-notice" class="text-xs text-zinc-400 mt-2 text-center hidden">
            Nota: Su respuesta será traducida al inglés para el técnico.
        </div>
    </div>

    <script>
        document.addEventListener('DOMContentLoaded', () => {
            const replyInput = document.getElementById('reply-input');
            const sendButton = document.getElementById('send-button');
            const chatWindow = document.getElementById('chat-window');
            const clearChatButton = document.getElementById('clear-chat');
            const translationNotice = document.getElementById('translation-notice');
            const langToggleText = document.getElementById('lang-toggle-text');
            const clearChatText = document.getElementById('clear-chat-text');
            const sendButtonText = document.getElementById('send-button-text');
            let sessionTimeout;
            let currentLanguage = 'en';
            let messageBatch = [];
            let batchTimer;
            let cleanupPrimed = false;

            const translations = {
                en: { header: "IT Support Chat", techLabel: "Technician", placeholder: "Type your reply here...", sendButton: "Send", timedOut: "This chat has timed out due to inactivity.", replySent: "Reply sent! This chat has timed out. You can now close this window.", toggleLang: "Español", sending: "Sending...", clearChat: "Clear Chat", endSession: "End & Reply", clearConfirmation: "Chat history will be cleared when the session ends." },
                es: { header: "Chat de Soporte de TI", techLabel: "Técnico", placeholder: "Escriba su respuesta aquí...", sendButton: "Enviar", timedOut: "Este chat ha expirado por inactividad.", replySent: "¡Respuesta enviada! El chat ha expirado. Ya puede cerrar esta ventana.", toggleLang: "English", sending: "Enviando...", clearChat: "Limpiar Chat", endSession: "Finalizar y Enviar", clearConfirmation: "El historial del chat se borrará cuando termine la sesión." }
            };

            function setLanguageUI(lang) {
                document.getElementById('main-header').textContent = translations[lang].header;
                document.querySelectorAll('.tech-label').forEach(el => el.textContent = translations[lang].techLabel);
                replyInput.placeholder = translations[lang].placeholder;
                
                sendButtonText.textContent = cleanupPrimed ? translations[lang].endSession : translations[lang].sendButton;
                langToggleText.textContent = translations[lang].toggleLang;
                clearChatText.textContent = cleanupPrimed ? translations[lang].endSession.split(' ')[0] : translations[lang].clearChat;
                
                document.querySelectorAll('.tech-message-content').forEach(el => { el.textContent = el.dataset[lang]; });
                if (lang === 'es') { translationNotice.classList.remove('hidden'); } else { translationNotice.classList.add('hidden'); }
                
                if (replyInput.disabled) {
                    if (replyInput.value.includes("timed out") || replyInput.value.includes("expirado")) { replyInput.value = translations[lang].timedOut; } 
                    else if (replyInput.value.includes("Reply sent") || replyInput.value.includes("Respuesta enviada")) { replyInput.value = translations[lang].replySent; }
                }
            }

            document.getElementById('lang-toggle').addEventListener('click', () => {
                currentLanguage = (currentLanguage === 'en') ? 'es' : 'en';
                setLanguageUI(currentLanguage);
            });

            function handleTimeout() {
                clearTimeout(batchTimer);
                replyInput.value = translations[currentLanguage].timedOut;
                replyInput.disabled = true;
                replyInput.classList.add('bg-red-900', 'text-red-300', 'border-red-700');
                sendButton.disabled = true;
                sendButton.classList.add('opacity-50', 'cursor-not-allowed');
            }

            sessionTimeout = setTimeout(handleTimeout, 300000); // 5 minutes

            function renderUserMessage(content) {
                const bubble = document.createElement('div');
                bubble.className = 'max-w-md p-4 rounded-lg shadow chat-bubble-user self-end';
                const contentP = document.createElement('p');
                contentP.className = 'text-sm whitespace-pre-wrap';
                contentP.textContent = content;
                bubble.appendChild(contentP);

                const statusSpan = document.createElement('span');
                statusSpan.className = 'sending-status text-xs italic text-white ml-2 dimming-text';
                statusSpan.textContent = translations[currentLanguage].sending;
                bubble.appendChild(statusSpan);

                chatWindow.appendChild(bubble);
                chatWindow.scrollTop = chatWindow.scrollHeight; 
            }

            function finalizeAndSend() {
                const finalMessage = messageBatch.join('\\n');
                if (!finalMessage) return;

                document.querySelectorAll('.sending-status').forEach(el => el.remove());

                const blob = new Blob([finalMessage], { type: 'text/plain' });
                const url = URL.createObjectURL(blob);
                const a = document.createElement('a');
                a.href = url;
                a.download = 'IT_Support_Reply.txt'; 
                document.body.appendChild(a);
                a.click();
                document.body.removeChild(a);
                URL.revokeObjectURL(url);

                replyInput.value = translations[currentLanguage].replySent;
                replyInput.disabled = true;
                sendButton.disabled = true;
                sendButton.classList.add('opacity-50', 'cursor-not-allowed');
            }

            function handleSend() {
                clearTimeout(sessionTimeout);
                clearTimeout(batchTimer);
                const userReply = replyInput.value.trim();
                if (!userReply) return;
                
                renderUserMessage(userReply);
                messageBatch.push(userReply);
                replyInput.value = '';
                
                batchTimer = setTimeout(finalizeAndSend, 15000);
            }
            
            replyInput.addEventListener('input', () => { if (batchTimer) { clearTimeout(batchTimer); batchTimer = setTimeout(finalizeAndSend, 15000); } });
            sendButton.addEventListener('click', handleSend);
            replyInput.addEventListener('keydown', (e) => { if (e.key === 'Enter') { e.preventDefault(); handleSend(); } });

            clearChatButton.addEventListener('click', () => {
                const signalBlob = new Blob([''], { type: 'text/plain' });
                const signalUrl = URL.createObjectURL(signalBlob);
                const a = document.createElement('a');
                a.href = signalUrl;
                a.download = 'Clear_Chat_Log.signal';
                document.body.appendChild(a);
                a.click();
                document.body.removeChild(a);
                URL.revokeObjectURL(signalUrl);

                cleanupPrimed = true;
                setLanguageUI(currentLanguage); 
                clearChatButton.classList.remove('bg-zinc-700');
                clearChatButton.classList.add('bg-yellow-500', 'hover:bg-yellow-600', 'text-black');
                sendButton.classList.remove('bg-green-600', 'hover:bg-green-700');
                sendButton.classList.add('bg-yellow-500', 'hover:bg-yellow-600', 'text-black');
                
                chatWindow.innerHTML = ''; 
                const confirmationDiv = document.createElement('div');
                confirmationDiv.className = 'flex flex-col items-center justify-center h-full text-center text-zinc-400 italic';
                confirmationDiv.textContent = translations[currentLanguage].clearConfirmation;
                chatWindow.appendChild(confirmationDiv);
            });

            window.onload = () => { chatWindow.scrollTop = chatWindow.scrollHeight; };
        });
    </script>
</body>
</html>
"@
    Set-Content -Path $HtmlFilePath -Value $htmlTemplate -Encoding UTF8
}


# --- Main Script Logic ---
try {
    # Check for a signal to clear the previous session before starting the new one.
    if (Test-Path $cleanupSignalFile) {
        Write-Output "User ended previous session. Clearing chat history and starting fresh."
        Clear-Content -Path $logFile -ErrorAction SilentlyContinue # Erase the log's content but keep the file
        Remove-Item $cleanupSignalFile -Force -ErrorAction SilentlyContinue # Remove the signal
    }

    # Clean up temporary files from the previous run, but leave the main log file.
    Cleanup-SessionFiles -FinalCleanup $false

    # --- Load or Create Chat History ---
    $chatHistory = [System.Collections.ArrayList]::new()
    if (Test-Path $logFile) {
        Write-Host "Existing chat log found. Loading history."
        # Read the log file, ignoring any blank lines
        $logLines = Get-Content -Path $logFile | Where-Object { $_.Trim() -ne '' }
        if ($logLines) {
            $chatHistory = [System.Collections.ArrayList]@(Parse-ChatLog -LogLines $logLines)
        }
    } else {
        Write-Host "No existing chat log found. Starting a new session."
    }

    # Add the new technician message to the log file and history
    if ($chatHistory.Count -gt 0) {
        # Append to an existing chat log
        Add-Content -Path $logFile -Value "`nTechnician: $TechMessage"
    }
    else {
        # Start a new log file or overwrite a cleared one
        Set-Content -Path $logFile -Value "Technician: $TechMessage"
    }
    $chatHistory.Add([PSCustomObject]@{ Sender = 'Technician'; Content = $TechMessage }) | Out-Null


    # --- Translate ALL Technician Messages for the UI ---
    Write-Host "Translating technician messages..."
    Add-Type -AssemblyName System.Web
    foreach ($message in $chatHistory) {
        if ($message.Sender -eq 'Technician') {
            $message | Add-Member -NotePropertyName SpanishContent -NotePropertyValue $message.Content # Fallback
            try {
                $encoded = [System.Web.HttpUtility]::UrlEncode($message.Content)
                $url = "https://api.mymemory.translated.net/get?q=$encoded&langpair=en|es"
                $response = Invoke-RestMethod -Uri $url -UseBasicParsing
                if ($response.responseData.translatedText) {
                    $decoded = [System.Web.HttpUtility]::HtmlDecode($response.responseData.translatedText)
                    $message.SpanishContent = $decoded -replace '<[^>]+>',''
                }
            } catch {
                Write-Warning "Could not translate message: $($message.Content)"
            }
        } else {
            # Add a placeholder for user messages so the HTML generation doesn't fail
            $message | Add-Member -NotePropertyName SpanishContent -NotePropertyValue $message.Content
        }
    }

    Update-ChatHtml -ChatHistory $chatHistory -HtmlFilePath $htmlFile

    try {
        $alertMessage = "You have a new message from IT Support. A window will now open.`n`nTiene un nuevo mensaje del soporte de TI. Se abrirá una ventana ahora."
        msg * $alertMessage
        Invoke-Item -Path $htmlFile
    } catch {
        Write-Warning "Could not send notification or open file."
    }

    Write-Host "Waiting for user reply... (5 minute timeout)"
    $timeout = (Get-Date).AddMinutes(5)
    $userReply = $null

    while ((Get-Date) -lt $timeout) {
        $replyFiles = Get-ChildItem -Path $downloadsPath -Filter "IT_Support_Reply*.txt*" -ErrorAction SilentlyContinue | Sort-Object CreationTime -Descending
        if ($replyFiles) {
            $newestReplyFile = $replyFiles[0]
            $readSuccess = $false
            $retryTimeout = (Get-Date).AddSeconds(10)
            while ((Get-Date) -lt $retryTimeout) {
                try {
                    $userReply = Get-Content -Path $newestReplyFile.FullName -Raw -ErrorAction Stop
                    $readSuccess = $true
                    break
                } catch { Start-Sleep -Milliseconds 200 }
            }
            if ($readSuccess) { break }
        }
        Start-Sleep -Seconds 3
    }

    if ($userReply) {
        $userReplyClean = $userReply -replace '\\n', [System.Environment]::NewLine
        
        # --- Add user reply to the log ---
        # This uses Add-Content because we know the file already exists with the technician's message
        Add-Content -Path $logFile -Value "`nUser: $userReplyClean"
        
        # --- Translate user's reply from Spanish to English ---
        Write-Host "Translating user reply to English..."
        $translatedReply = ""
        try {
            $encodedUserReply = [System.Web.HttpUtility]::UrlEncode($userReplyClean)
            $replyApiUrl = "https://api.mymemory.translated.net/get?q=$encodedUserReply&langpair=es|en"
            $replyResponse = Invoke-RestMethod -Uri $replyApiUrl -UseBasicParsing
            if ($replyResponse.responseData.translatedText) {
                $rawReplyTranslation = $replyResponse.responseData.translatedText
                $decodedReplyTranslation = [System.Web.HttpUtility]::HtmlDecode($rawReplyTranslation)
                $translatedReply = $decodedReplyTranslation -replace '<[^>]+>',''
                Write-Host "User reply translation successful."
            }
        } catch {
            Write-Warning "Could not translate user reply."
        }
        
        # --- Build a concise final report ---
        $finalOutput = @"
========================================
       IT SUPPORT CHAT RESULT
========================================

Technician's Message:
---------------------
$TechMessage

User's Reply (Original):
------------------------
$userReplyClean
"@
        # Only add the translation block if it's different from the original and not empty
        if ($translatedReply -and ($translatedReply.Trim() -ne $userReplyClean.Trim())) {
            $translationBlock = @"

User's Reply (Translated to English):
-------------------------------------
$translatedReply
"@
            $finalOutput += $translationBlock
        }
        $finalOutput += "`n========================================`n"
        Write-Output $finalOutput

    } else {
        $timeoutOutput = @"
========================================
       IT SUPPORT CHAT RESULT
========================================
Result: Timed out. No reply received from user within 5 minutes.
Technician's Original Message:
------------------------------
$TechMessage
========================================
"@
        Write-Output $timeoutOutput
        # Since it timed out, we assume the session is over.
        Cleanup-SessionFiles -FinalCleanup $true
    }

} finally {
    # This block will run at the end of every execution.
    # It cleans up volatile files but intentionally leaves the chatlog and signal file.
    Cleanup-SessionFiles -FinalCleanup $false
}
