let cable = null;
let subscription = null;
let currentUsername = '';
let currentRoom = 'general';

function log(msg, type = 'info') {
  console.log(`[${new Date().toLocaleTimeString()}] ${msg}`);
  const statusEl = document.getElementById('status');
  statusEl.textContent = `Stan: ${msg}`;
  statusEl.className = type === 'error' ? 'error' : 'connected';
}

function joinChat() {
  const usernameInput = document.getElementById('username').value.trim();
  const roomInput = document.getElementById('room').value.trim() || 'general';

  if (!usernameInput) {
    alert('⚠️ Wpisz swój nick!');
    return;
  }

  if (usernameInput.length < 2) {
    alert('⚠️ Nick musi mieć co najmniej 2 znaki!');
    return;
  }

  currentUsername = usernameInput;
  currentRoom = roomInput;

  document.getElementById('setup').style.display = 'none';
  document.getElementById('chatMain').style.display = 'flex';

  connectToChat();
}

function connectToChat() {
  const PROTOCOL = window.location.protocol;
  const HOST = window.location.hostname;
  const PORT = window.location.port || '3000';
  const CABLE_URL = `${PROTOCOL}//${HOST}:${PORT}/cable`;

  log(`Łączenie z: ${CABLE_URL}`);

  cable = ActionCable.createConsumer(CABLE_URL);

  subscription = cable.subscriptions.create(
    { channel: 'ChatChannel', room: currentRoom },
    {
      connected() {
        log('✅ Połączono z serwerem!', 'connected');
        addSystemMessage('✅ Połączono z serwerem!');
        loadMessages();
      },
      disconnected() {
        log('⚠️ Rozłączono', 'error');
        addSystemMessage('⚠️ Rozłączono z serwerem');
      },
      rejected() {
        log('❌ Odrzucono połączenie', 'error');
        addSystemMessage('❌ Nie udało się połączyć z serwerem');
      },
      received(data) {
        if (data.action === 'new_message') {
          displayMessage(data.message, false);
        }
      }
    }
  );
}

function loadMessages() {
  const PROTOCOL = window.location.protocol;
  const HOST = window.location.hostname;
  const PORT = window.location.port || '3000';
  const API_BASE = `${PROTOCOL}//${HOST}:${PORT}`;

  fetch(`${API_BASE}/messages?room=${currentRoom}`)
    .then(response => response.json())
    .then(messages => {
      const messagesEl = document.getElementById('messages');
      messagesEl.innerHTML = '';

      if (messages.length === 0) {
        addSystemMessage('💬 Brak wiadomości w tym pokoju. Bądź pierwszy!');
      } else {
        messages.forEach(msg => displayMessage(msg, true));
      }
    })
    .catch(error => {
      console.error('Błąd ładowania wiadomości:', error);
      addSystemMessage('❌ Błąd ładowania wiadomości');
    });
}

function sendMessage() {
  const input = document.getElementById('messageInput');
  const content = input.value.trim();

  if (!content) return;
  if (content.length > 500) {
    alert('⚠️ Wiadomość może mieć maksymalnie 500 znaków!');
    return;
  }

  const PROTOCOL = window.location.protocol;
  const HOST = window.location.hostname;
  const PORT = window.location.port || '3000';
  const API_BASE = `${PROTOCOL}//${HOST}:${PORT}`;

  const messageData = {
    message: {
      content: content,
      username: currentUsername,
      room: currentRoom
    }
  };

  fetch(`${API_BASE}/messages`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(messageData)
  })
    .then(response => response.json())
    .then(data => {
      input.value = '';
      input.focus();
    })
    .catch(error => {
      console.error('Błąd wysyłania:', error);
      addSystemMessage('❌ Nie udało się wysłać wiadomości');
    });
}

function displayMessage(message, isHistory = false) {
  const messagesEl = document.getElementById('messages');
  const isUser = message.username === currentUsername;

  const messageEl = document.createElement('div');
  messageEl.className = `message ${isUser ? 'user' : 'other'}`;

  const usernameEl = document.createElement('span');
  usernameEl.className = 'username';
  usernameEl.textContent = message.username;
  messageEl.appendChild(usernameEl);

  const contentEl = document.createElement('span');
  contentEl.className = 'content';
  contentEl.textContent = message.content;
  messageEl.appendChild(contentEl);

  const timestampEl = document.createElement('span');
  timestampEl.className = 'timestamp';
  const date = new Date(message.created_at || new Date());
  timestampEl.textContent = date.toLocaleTimeString('pl-PL', { hour: '2-digit', minute: '2-digit' });
  messageEl.appendChild(timestampEl);

  if (isHistory) {
    messagesEl.appendChild(messageEl);
  } else {
    messagesEl.appendChild(messageEl);
    messagesEl.scrollTop = messagesEl.scrollHeight;
  }
}

function addSystemMessage(text) {
  const messagesEl = document.getElementById('messages');
  const messageEl = document.createElement('div');
  messageEl.className = 'message system';
  messageEl.textContent = text;
  messagesEl.appendChild(messageEl);
  messagesEl.scrollTop = messagesEl.scrollHeight;
}

document.addEventListener('DOMContentLoaded', () => {
  const messageInput = document.getElementById('messageInput');
  if (messageInput) {
    messageInput.addEventListener('keypress', (e) => {
      if (e.key === 'Enter') {
        sendMessage();
      }
    });
  }
});
