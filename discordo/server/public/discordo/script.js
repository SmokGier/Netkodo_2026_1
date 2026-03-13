// ========== GLOBALNE ZMIENNE ==========
var cable = null;
var subscription = null;
var dmSubscription = null;
var currentUserId = null;
var currentUsername = '';
var currentUserIsAdmin = false;
var currentChatServerId = null;
var currentChatServerName = null;
var currentChatServerOwnerId = null;
var currentDMUserId = null;
var currentDMUsername = null;
var theme = localStorage.getItem('theme') || 'dark';

console.log('✅ Discordo loaded! Sprawdzam sesję...');

// ========== POMOCNICZA FUNKCJA DLA ZAUTORYZOWANYCH ŻĄDAŃ ==========
function authFetch(url, options = {}) {
  const token = localStorage.getItem('auth_token');
  if (token) {
    options.headers = options.headers || {};
    options.headers['X-Authorization'] = token;
  }
  options.credentials = options.credentials || 'include';
  return fetch(url, options);
}

// ========== EVENT LISTENERS ==========
document.addEventListener('DOMContentLoaded', function() {
  document.body.setAttribute('data-theme', theme);
  
  // ✅ PRZYWRACANIE SESJI Z LOCALSTORAGE
  const token = localStorage.getItem('auth_token');
  const userDataStr = localStorage.getItem('user_data');
  console.log('🔍 Próba przywrócenia sesji z localStorage');
  console.log('Token:', token ? '✓ ISTNIEJE' : '✗ BRAK');
  console.log('User ', userDataStr ? '✓ ISTNIEJE' : '✗ BRAK');
  
  if (token && userDataStr) {
    try {
      const userData = JSON.parse(userDataStr);
      currentUserId = userData.id;
      currentUsername = userData.username;
      currentUserIsAdmin = userData.is_admin;
      
      console.log('✅ Sesja przywrócona dla użytkownika:', currentUsername);
      
      const authContainer = document.getElementById('authContainer');
      const discordApp = document.getElementById('discordApp');
      if (authContainer && discordApp) {
        authContainer.style.display = 'none';
        discordApp.style.display = 'flex';
        loadChatServers();
        connectToDMChannel();
        createLogoutButton();
      }
    } catch (e) {
      console.error('❌ Błąd przywracania sesji:', e);
      localStorage.removeItem('auth_token');
      localStorage.removeItem('user_data');
    }
  }
  
  var loginForm = document.getElementById('loginForm');
  var registerForm = document.getElementById('registerForm');
  var themeToggleBtn = document.getElementById('themeToggleBtn');
  var loginTab = document.getElementById('loginTab');
  var registerTab = document.getElementById('registerTab');
  var loginButton = document.getElementById('loginButton');
  var registerButton = document.getElementById('registerButton');
  var addServer = document.getElementById('addServer');
  var cancelServer = document.getElementById('cancelServer');
  var createServerButton = document.getElementById('createServerButton');
  var privateServer = document.getElementById('privateServer');
  var sendButton = document.getElementById('sendButton');
  var msgInput = document.getElementById('messageInput');
  var loginPassword = document.getElementById('loginPassword');
  var registerPasswordConfirm = document.getElementById('registerPasswordConfirm');
  
  if (loginForm) {
    loginForm.addEventListener('submit', function(e) {
      e.preventDefault();
      login();
    });
  }
  
  if (registerForm) {
    registerForm.addEventListener('submit', function(e) {
      e.preventDefault();
      register();
    });
  }
  
  if (themeToggleBtn) {
    themeToggleBtn.textContent = theme === 'dark' ? '☀️' : '🌙';
    themeToggleBtn.addEventListener('click', toggleTheme);
  }
  
  if (loginTab && registerTab) {
    loginTab.addEventListener('click', function() {
      loginTab.className = 'active';
      registerTab.className = '';
      loginForm.style.display = 'flex';
      registerForm.style.display = 'none';
    });
    
    registerTab.addEventListener('click', function() {
      loginTab.className = '';
      registerTab.className = 'active';
      loginForm.style.display = 'none';
      registerForm.style.display = 'flex';
    });
  }
  
  if (loginButton) loginButton.addEventListener('click', login);
  if (registerButton) registerButton.addEventListener('click', register);
  if (addServer) addServer.addEventListener('click', showCreateServerModal);
  if (cancelServer) cancelServer.addEventListener('click', hideCreateServerModal);
  if (createServerButton) createServerButton.addEventListener('click', createServer);
  if (privateServer) privateServer.addEventListener('change', togglePasswordField);
  if (sendButton) sendButton.addEventListener('click', sendMessage);
  
  if (msgInput) {
    msgInput.addEventListener('keypress', function(e) {
      if (e.key === 'Enter') sendMessage();
    });
  }
  
  if (loginPassword) {
    loginPassword.addEventListener('keydown', function(e) {
      if (e.key === 'Enter') {
        e.preventDefault();
        login();
      }
    });
  }
  
  if (registerPasswordConfirm) {
    registerPasswordConfirm.addEventListener('keydown', function(e) {
      if (e.key === 'Enter') {
        e.preventDefault();
        register();
      }
    });
  }
});

function toggleTheme() {
  theme = theme === 'dark' ? 'light' : 'dark';
  document.body.setAttribute('data-theme', theme);
  localStorage.setItem('theme', theme);
  
  var themeToggleBtn = document.getElementById('themeToggleBtn');
  if (themeToggleBtn) {
    themeToggleBtn.textContent = theme === 'dark' ? '☀️' : '🌙';
  }
}

function login() {
  var username = document.getElementById('loginUsername').value.trim();
  var password = document.getElementById('loginPassword').value;
  
  if (!username || !password) {
    showError('login', 'Wypełnij wszystkie pola!');
    return;
  }
  
  fetch('/login', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ username: username, password: password }),
    credentials: 'include'
  })
  .then(function(response) { return response.json(); })
  .then(function(data) {
    if (data.success) {
      currentUserId = data.user.id;
      currentUsername = data.user.username;
      currentUserIsAdmin = data.user.is_admin;
      
      localStorage.setItem('auth_token', data.user.api_token);
      localStorage.setItem('user_data', JSON.stringify({
        id: data.user.id,
        username: data.user.username,
        is_admin: data.user.is_admin
      }));
      
      console.log('✅ Zapisano sesję do localStorage:', { 
        token: '***', 
        user: data.user.username 
      });
      
      var authContainer = document.getElementById('authContainer');
      var discordApp = document.getElementById('discordApp');
      
      if (authContainer && discordApp) {
        authContainer.style.display = 'none';
        discordApp.style.display = 'flex';
        loadChatServers();
        connectToDMChannel();
        createLogoutButton();
      }
    } else {
      showError('login', data.error || 'Błąd logowania');
    }
  })
  .catch(function() {
    showError('login', 'Błąd połączenia z serwerem');
  });
}

function register() {
  var username = document.getElementById('registerUsername').value.trim();
  var password = document.getElementById('registerPassword').value;
  var passwordConfirm = document.getElementById('registerPasswordConfirm').value;
  
  if (!username || !password || !passwordConfirm) {
    showError('register', 'Wypełnij wszystkie pola!');
    return;
  }
  
  if (password !== passwordConfirm) {
    showError('register', 'Hasła nie są identyczne!');
    return;
  }
  
  if (password.length < 6) {
    showError('register', 'Hasło musi mieć min. 6 znaków!');
    return;
  }
  
  fetch('/users', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ 
      user: { 
        username: username, 
        password: password, 
        password_confirmation: passwordConfirm 
      } 
    }),
    credentials: 'include'
  })
  .then(function(response) { return response.json(); })
  .then(function(data) {
    if (data.success) {
      currentUserId = data.user.id;
      currentUsername = data.user.username;
      
      localStorage.setItem('auth_token', data.user.api_token);
      localStorage.setItem('user_data', JSON.stringify({
        id: data.user.id,
        username: data.user.username,
        is_admin: data.user.is_admin
      }));
      
      console.log('✅ Zapisano sesję do localStorage:', { 
        token: '***', 
        user: data.user.username 
      });
      
      var authContainer = document.getElementById('authContainer');
      var discordApp = document.getElementById('discordApp');
      
      if (authContainer && discordApp) {
        authContainer.style.display = 'none';
        discordApp.style.display = 'flex';
        loadChatServers();
        connectToDMChannel();
        createLogoutButton();
      }
    } else {
      showError('register', data.errors ? data.errors.join(', ') : 'Błąd rejestracji');
    }
  })
  .catch(function() {
    showError('register', 'Błąd połączenia z serwerem');
  });
}

function showError(form, message) {
  var el = document.getElementById(form + 'Error');
  if (el) {
    el.textContent = message;
    setTimeout(function() { el.textContent = ''; }, 3000);
  }
}

function loadChatServers() {
  authFetch('/chat_servers')
  .then(function(response) { return response.json(); })
  .then(function(servers) {
    var list = document.getElementById('serverList');
    if (!list) return;
    
    list.innerHTML = '';
    
    var homeBtn = document.createElement('div');
    homeBtn.className = 'server-icon active';
    homeBtn.textContent = '🏠';
    homeBtn.title = 'Wiadomości prywatne';
    homeBtn.addEventListener('click', showDMList);
    list.appendChild(homeBtn);
    
    servers.forEach(function(server) {
      var el = document.createElement('div');
      el.className = 'server-icon';
      el.textContent = server.name.charAt(0).toUpperCase();
      el.title = server.name + (server.private ? ' 🔒' : '');
      
      el.addEventListener('click', (function(id, name) {
        return function() { joinChatServer(id, name); };
      })(server.id, server.name));
      
      list.appendChild(el);
    });
    
    showDMList();
  })
  .catch(function(error) {
    console.error('Błąd ładowania serwerów:', error);
    showDMList();
  });
}

function showDMList() {
  if (dmSubscription) {
    dmSubscription.unsubscribe();
    dmSubscription = null;
  }
  
  currentChatServerId = null;
  currentChatServerName = 'DM';
  currentChatServerOwnerId = null;
  currentDMUserId = null;
  currentDMUsername = null;
  
  document.getElementById('currentChannelName').textContent = '💬 Wiadomości prywatne';
  
  if (subscription) {
    subscription.unsubscribe();
    subscription = null;
  }
  
  var el = document.getElementById('messages');
  if (!el) return;
  
  el.innerHTML = '<div class="system-message">🔒 Kliknij użytkownika aby rozpocząć czat prywatny</div>';
  
  authFetch('/direct_messages/users')
  .then(function(response) { return response.json(); })
  .then(function(users) {
    users.forEach(function(user) {
      if (user.id === currentUserId) return;
      
      var userEl = document.createElement('div');
      userEl.className = 'message system';
      userEl.innerHTML = `<strong>${user.username}</strong>`;
      userEl.style.cursor = 'pointer';
      userEl.style.padding = '10px';
      userEl.style.borderBottom = '1px solid #2f3136';
      
      userEl.addEventListener('click', function() {
        startDMChat(user.id, user.username);
      });
      
      el.appendChild(userEl);
    });
  })
  .catch(function(error) {
    console.error('Błąd ładowania użytkowników:', error);
    el.innerHTML += '<div class="system-message">❌ Błąd ładowania listy użytkowników</div>';
  });
}

function startDMChat(userId, username) {
  currentDMUserId = userId;
  currentDMUsername = username;
  currentChatServerId = null;
  currentChatServerName = `DM-${username}`;
  currentChatServerOwnerId = null;
  
  document.getElementById('currentChannelName').textContent = `🔒 Prywatny czat z ${username}`;
  
  var el = document.getElementById('messages');
  if (!el) return;
  
  el.innerHTML = `<div class="system-message">💬 Czat z ${username}</div>`;
  
  // ✅ KLUCZOWA ZMIANA: WYMUSZENIE ODŚWIEŻENIA SUBSKRYPCJI DM PRZY WEJŚCIU DO CZATU
  if (dmSubscription) {
    dmSubscription.unsubscribe();
    dmSubscription = null;
  }
  connectToDMChannel();
  
  loadDMMessages(userId);
}

function loadDMMessages(userId) {
  authFetch(`/direct_messages/${userId}`)
  .then(function(response) { return response.json(); })
  .then(function(messages) {
    var el = document.getElementById('messages');
    if (!el) return;
    
    var isAtBottom = el.scrollHeight - el.scrollTop === el.clientHeight;
    var existingIds = Array.from(el.querySelectorAll('.message')).map(function(msg) {
      return msg.dataset.messageId;
    });
    
    messages.forEach(function(message) {
      if (!existingIds.includes(message.id.toString())) {
        displayDMMessage(message, false);
      }
    });
    
    if (isAtBottom) {
      el.scrollTop = el.scrollHeight;
    }
  })
  .catch(function(error) {
    console.error('Błąd ładowania DM:', error);
  });
}

function displayDMMessage(message, isHistory) {
  var el = document.getElementById('messages');
  if (!el || !message) return;
  
  if (el.querySelector('.message[data-message-id="' + message.id + '"]')) {
    return;
  }
  
  var msgEl = document.createElement('div');
  msgEl.className = 'message';
  msgEl.dataset.messageId = message.id;
  
  var isOwnMessage = message.sender_id === currentUserId;
  if (isOwnMessage) {
    msgEl.classList.add('own-message');
  }
  
  var avatarEl = document.createElement('div');
  avatarEl.className = 'avatar';
  avatarEl.style.background = stringToColor(message.sender_username || 'Anonymous');
  avatarEl.textContent = (message.sender_username || '?').charAt(0).toUpperCase();
  
  var contentEl = document.createElement('div');
  contentEl.className = 'message-content';
  
  var usernameEl = document.createElement('div');
  usernameEl.className = 'username';
  usernameEl.textContent = message.sender_username || 'Anonymous';
  
  var textEl = document.createElement('div');
  textEl.className = 'content';
  textEl.textContent = replaceEmojis(message.content);
  
  var timestampEl = document.createElement('div');
  timestampEl.className = 'timestamp';
  var date = new Date(message.created_at || new Date());
  timestampEl.textContent = date.toLocaleTimeString('pl-PL', { hour: '2-digit', minute: '2-digit' });
  
  contentEl.appendChild(usernameEl);
  contentEl.appendChild(textEl);
  contentEl.appendChild(timestampEl);
  
  msgEl.appendChild(avatarEl);
  msgEl.appendChild(contentEl);
  
  el.appendChild(msgEl);
  
  if (!isHistory) {
    el.scrollTop = el.scrollHeight;
  }
}

function connectToDMChannel() {
  console.log('🔌 Łączenie z DM Channel... currentUserId:', currentUserId);
  
  if (dmSubscription) {
    console.log('🔌 Odłączam starą subskrypcję DM');
    dmSubscription.unsubscribe();
    dmSubscription = null;
  }
  
  if (!cable) {
    console.log('🔌 Tworzę nowe połączenie WebSocket');
    cable = ActionCable.createConsumer('/cable');
  }
  
  if (currentUserId) {
    console.log('🔌 Subskrybuję kanał: dm_channel_' + currentUserId);
    
    dmSubscription = cable.subscriptions.create(
      { 
        channel: 'DirectMessageChannel', 
        user_id: currentUserId.toString()
      },
      {
        connected: function() {
          console.log('✅ WebSocket DM POŁĄCZONY! Nasłuchiwanie na dm_channel_' + currentUserId);
        },
        disconnected: function() {
          console.log('❌ WebSocket DM ROZŁĄCZONY!');
        },
        rejected: function() {
          console.log('❌ WebSocket DM ODRZUCONY!');
        },
        received: function(data) {
          console.log('📨 Otrzymano dane z DM Channel:', data);
          
          if (data.action === 'new_dm' && data.message) {
            console.log('📨 Nowa wiadomość DM:', data.message);
            console.log('📨 currentDMUserId:', currentDMUserId);
            console.log('📨 Sprawdzam: sender_id=' + data.message.sender_id + ', recipient_id=' + data.message.recipient_id);
            
            if (currentDMUserId) {
              if (data.message.sender_id == currentDMUserId || data.message.recipient_id == currentDMUserId) {
                console.log('✅ Wiadomość pasuje do bieżącego czatu - wyświetlam!');
                displayDMMessage(data.message, false);
              } else {
                console.log('⚠️ Wiadomość NIE pasuje do bieżącego czatu (to inny użytkownik)');
              }
            } else {
              console.log('⚠️ Nie jesteś w żadnym czacie DM - pomijam wiadomość');
            }
          } else {
            console.log('⚠️ Otrzymano dane ale nie są wiadomością DM:', data);
          }
        }
      }
    );
  } else {
    console.log('⚠️ currentUserId nie jest ustawione - nie mogę subskrybować DM Channel');
  }
}

function joinChatServer(chatServerId, chatServerName) {
  authFetch('/chat_servers/' + chatServerId + '/join', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ password: '' })
  })
  .then(function(response) {
    if (response.ok) {
      return response.json();
    } else {
      if (response.status === 401) {
        var password = prompt('Wprowadź hasło dla serwera "' + chatServerName + '":');
        if (password !== null) {
          return authFetch('/chat_servers/' + chatServerId + '/join', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ password: password })
          }).then(function(response) {
            if (response.ok) {
              return response.json();
            } else {
              alert('Nieprawidłowe hasło!');
              throw new Error('Nieprawidłowe hasło');
            }
          });
        } else {
          throw new Error('Anulowano');
        }
      } else {
        throw new Error('Błąd dołączania');
      }
    }
  })
  .then(function(data) {
    if (data) {
      setCurrentServer(data.id, data.name, data.owner_id);
    }
  })
  .catch(function(error) {
    console.error('Błąd dołączania do serwera:', error);
    if (error.message !== 'Anulowano') {
      alert('Nie udało się dołączyć do serwera: ' + error.message);
    }
  });
}

function setCurrentServer(chatServerId, chatServerName, ownerId) {
  currentChatServerId = chatServerId;
  currentChatServerName = chatServerName;
  currentChatServerOwnerId = ownerId;
  currentDMUserId = null;
  currentDMUsername = null;
  
  document.getElementById('currentChannelName').textContent = '# ' + chatServerName;
  
  if (subscription) {
    subscription.unsubscribe();
    subscription = null;
  }
  
  // ✅ WYCZYŚĆ KONTENER I POKAŻ "ŁADOWANIE"
  var el = document.getElementById('messages');
  if (el) {
    el.innerHTML = '<div class="system-message">💬 Ładowanie historii...</div>';
  }
  
  // ✅ ŁADUJ NATYCHMIAST (NIE CZKAJ NA WEBSOCKET)
  setTimeout(loadMessages, 100);
  
  // ✅ POŁĄCZ Z WEBSOCKET DLA NOWYCH WIADOMOŚCI
  connectToChat();
}

function showCreateServerModal() {
  document.getElementById('createServerModal').style.display = 'flex';
}

function hideCreateServerModal() {
  document.getElementById('createServerModal').style.display = 'none';
  document.getElementById('serverNameInput').value = '';
  document.getElementById('serverPassword').value = '';
  document.getElementById('serverPasswordConfirm').value = '';
  document.getElementById('privateServer').checked = false;
  document.getElementById('serverPassword').style.display = 'none';
  document.getElementById('serverPasswordConfirm').style.display = 'none';
  document.getElementById('serverError').textContent = '';
}

function togglePasswordField() {
  var checked = document.getElementById('privateServer').checked;
  document.getElementById('serverPassword').style.display = checked ? 'block' : 'none';
  document.getElementById('serverPasswordConfirm').style.display = checked ? 'block' : 'none';
}

function createServer() {
  console.log('🔧 Próba utworzenia serwera...');
  
  var name = document.getElementById('serverNameInput').value.trim();
  var isPrivate = document.getElementById('privateServer').checked;
  var password = document.getElementById('serverPassword').value;
  var passwordConfirm = document.getElementById('serverPasswordConfirm').value;
  
  console.log('🔧 Dane serwera:', { name, isPrivate, password: password ? '***' : 'brak' });
  
  if (!name) {
    showErrorServer('Wpisz nazwę serwera!');
    console.error('❌ Błąd: Brak nazwy serwera');
    return;
  }
  
  if (isPrivate) {
    if (!password || !passwordConfirm) {
      showErrorServer('Wypełnij pola hasła!');
      console.error('❌ Błąd: Brak hasła dla prywatnego serwera');
      return;
    }
    if (password !== passwordConfirm) {
      showErrorServer('Hasła nie są identyczne!');
      console.error('❌ Błąd: Hasła nie pasują');
      return;
    }
    if (password.length < 6) {
      showErrorServer('Hasło musi mieć min. 6 znaków!');
      console.error('❌ Błąd: Hasło za krótkie');
      return;
    }
  }
  
  var data = { chat_server: { name: name } };
  if (isPrivate) {
    data.chat_server.password = password;
    data.chat_server.password_confirmation = passwordConfirm;
  }
  
  console.log('📤 Wysyłanie żądania do /chat_servers:', data);
  
  authFetch('/chat_servers', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(data)
  })
  .then(function(response) {
    console.log('📥 Odpowiedź z serwera:', response.status);
    return response.json().then(function(json) {
      if (!response.ok) throw json;
      return json;
    });
  })
  .then(function() {
    console.log('✅ Serwer utworzony pomyślnie!');
    hideCreateServerModal();
    loadChatServers();
  })
  .catch(function(error) {
    console.error('❌ Błąd tworzenia serwera:', error);
    showErrorServer(error.errors ? error.errors.join(', ') : 'Błąd połączenia z serwerem');
  });
}

function showErrorServer(message) {
  var el = document.getElementById('serverError');
  if (el) {
    el.textContent = message;
    setTimeout(function() { el.textContent = ''; }, 3000);
  }
}

function connectToChat() {
  if (subscription) {
    subscription.unsubscribe();
    subscription = null;
  }
  
  if (!cable) {
    cable = ActionCable.createConsumer('/cable');
  }
  
  if (currentChatServerId) {
    subscription = cable.subscriptions.create(
      { 
        channel: 'ChatChannel', 
        chat_server_id: currentChatServerId.toString()
      },
      {
        // ✅ USUNIĘTO: connected: function() { loadMessages(); }
        // Teraz loadMessages jest wywoływane WYŁĄCZNIE w setCurrentServer
        received: function(data) {
          if (data.action === 'new_message' && data.message) {
            displayMessage(data.message, false);
          } else if (data.action === 'update_reactions') {
            updateReactionsForMessage(data.message_id, data.reactions);
          }
        }
      }
    );
  }
}

function loadMessages() {
  // ✅ BEZPIECZNE SPRAWDZENIE: czy jesteśmy na serwerze
  if (!currentChatServerId) {
    console.log('⚠️ Nie jesteśmy na serwerze - pomijam ładowanie wiadomości');
    return;
  }
  
  authFetch('/messages?chat_server_id=' + currentChatServerId)
  .then(function(response) { 
    if (!response.ok) throw new Error('Błąd ' + response.status);
    return response.json(); 
  })
  .then(function(messages) {
    var el = document.getElementById('messages');
    if (!el) return;
    
    // ✅ USUŃ "ŁADOWANIE" I POKAŻ WIADOMOŚCI
    el.innerHTML = '';
    
    if (messages.length === 0) {
      addSystemMessage('💬 Brak wiadomości w #' + currentChatServerName + '. Bądź pierwszy!');
    } else {
      for (var i = 0; i < messages.length; i++) {
        displayMessage(messages[i], true);
      }
    }
    
    el.scrollTop = el.scrollHeight;
  })
  .catch(function(error) {
    console.error('❌ Błąd ładowania wiadomości:', error);
    var el = document.getElementById('messages');
    if (el) {
      el.innerHTML = '<div class="system-message">❌ Błąd ładowania historii</div>';
    }
  });
}

function deleteMessage(messageId) {
  if (!confirm('Czy na pewno chcesz usunąć tę wiadomość?')) return;
  
  // ✅ OKREŚL CZY TO WIADOMOŚĆ SERWEROWA CZY DM
  var isDM = currentDMUserId !== null;
  var url = isDM ? '/direct_messages/' + messageId : '/messages/' + messageId;
  
  console.log('🗑️ Usuwanie wiadomości:', { id: messageId, type: isDM ? 'DM' : 'serwerowa', url: url });
  
  authFetch(url, {
    method: 'DELETE'
  })
  .then(function(response) {
    console.log('🗑️ Odpowiedź:', response.status);
    
    if (response.ok) {
      // ✅ USUŃ Z UI
      var msgEl = document.querySelector('.message[data-message-id="' + messageId + '"]');
      if (msgEl) {
        msgEl.style.opacity = '0';
        msgEl.style.transform = 'translateX(-20px)';
        setTimeout(function() {
          msgEl.remove();
          console.log('✅ Wiadomość usunięta z UI');
        }, 300);
      }
    } else {
      return response.json().then(function(data) {
        var errorMsg = data.error || 'Nie masz uprawnień do usunięcia tej wiadomości';
        console.error('❌ Błąd usuwania:', errorMsg);
        alert('❌ ' + errorMsg);
      });
    }
  })
  .catch(function(error) {
    console.error('❌ Błąd połączenia:', error);
    alert('Błąd połączenia z serwerem');
  });
}

function displayMessage(message, isHistory) {
  var el = document.getElementById('messages');
  if (!el || !message) return;
  
  var msgEl = document.createElement('div');
  msgEl.className = 'message';
  msgEl.dataset.messageId = message.id;
  if (message.user_id == currentUserId) msgEl.classList.add('own-message');
  
  var decryptedContent = replaceEmojis(message.content);
  if (currentUsername && decryptedContent.includes('@' + currentUsername)) {
    msgEl.classList.add('mentioned');
  }
  
  var avatarEl = document.createElement('div');
  avatarEl.className = 'avatar';
  avatarEl.style.background = stringToColor(message.username);
  avatarEl.textContent = message.username.charAt(0).toUpperCase();
  
  var contentEl = document.createElement('div');
  contentEl.className = 'message-content';
  
  var usernameEl = document.createElement('div');
  usernameEl.className = 'username';
  usernameEl.textContent = message.username;
  
  if (message.user_id == currentUserId || currentUserIsAdmin || currentChatServerOwnerId == currentUserId) {
    var deleteBtn = document.createElement('button');
    deleteBtn.className = 'delete-btn';
    deleteBtn.innerHTML = '🗑️';
    deleteBtn.style.float = 'right';
    deleteBtn.style.background = 'none';
    deleteBtn.style.border = 'none';
    deleteBtn.style.cursor = 'pointer';
    deleteBtn.style.opacity = '0.6';
    deleteBtn.onmouseover = function() { this.style.opacity = '1'; };
    deleteBtn.onmouseout = function() { this.style.opacity = '0.6'; };
    deleteBtn.onclick = function(e) {
      e.stopPropagation();
      deleteMessage(message.id);
    };
    usernameEl.appendChild(deleteBtn);
  }
  
  var textEl = document.createElement('div');
  textEl.className = 'content';
  
  var mentionRegex = /@(\w+)/g;
  var highlightedContent = decryptedContent.replace(mentionRegex, function(match, username) {
    return '<span class="mention">' + match + '</span>';
  });
  textEl.innerHTML = highlightedContent;
  
  var timestampEl = document.createElement('div');
  timestampEl.className = 'timestamp';
  var date = new Date(message.created_at || new Date());
  timestampEl.textContent = date.toLocaleTimeString('pl-PL', { hour: '2-digit', minute: '2-digit' });
  
  var reactionsEl = document.createElement('div');
  reactionsEl.className = 'reactions';
  reactionsEl.dataset.messageId = message.id;
  
  if (message.reactions) {
    for (var emoji in message.reactions) {
      var count = message.reactions[emoji];
      var reactionEl = document.createElement('span');
      reactionEl.className = 'reaction';
      reactionEl.dataset.emoji = emoji;
      reactionEl.innerHTML = emoji + ' ' + count;
      reactionEl.onclick = (function(msgId, e) {
        return function() { toggleReaction(msgId, e); };
      })(message.id, emoji);
      reactionsEl.appendChild(reactionEl);
    }
  }
  
  var addReactionBtn = document.createElement('button');
  addReactionBtn.className = 'add-reaction';
  addReactionBtn.innerHTML = '👍';
  addReactionBtn.onclick = function() { showReactionPicker(message.id); };
  reactionsEl.appendChild(addReactionBtn);
  
  contentEl.appendChild(usernameEl);
  contentEl.appendChild(textEl);
  contentEl.appendChild(timestampEl);
  contentEl.appendChild(reactionsEl);
  
  msgEl.appendChild(avatarEl);
  msgEl.appendChild(contentEl);
  
  el.appendChild(msgEl);
  
  if (!isHistory) {
    el.scrollTop = el.scrollHeight;
  }
}

function addSystemMessage(text) {
  var el = document.getElementById('messages');
  if (!el) return;
  
  var msg = document.createElement('div');
  msg.className = 'message system';
  msg.textContent = text;
  el.appendChild(msg);
  el.scrollTop = el.scrollHeight;
}

function stringToColor(str) {
  var hash = 0;
  for (var i = 0; i < str.length; i++) {
    hash = str.charCodeAt(i) + ((hash << 5) - hash);
  }
  var colors = [
    '#5865f2', '#4752c4', '#3ba55d', '#f04747', 
    '#faa61a', '#747f8d', '#576574', '#eb459e'
  ];
  return colors[Math.abs(hash) % colors.length];
}

function replaceEmojis(text) {
  return text
    .replace(/:\)/g, '😊')
    .replace(/:\(/g, '😢')
    .replace(/:D/g, '😄')
    .replace(/<3/g, '❤️');
}

function updateReactionsForMessage(messageId, reactionsHash) {
  var reactionsEl = document.querySelector('.reactions[data-message-id="' + messageId + '"]');
  if (!reactionsEl) return;
  
  var addBtn = reactionsEl.querySelector('.add-reaction');
  reactionsEl.innerHTML = '';
  
  if (addBtn) {
    reactionsEl.appendChild(addBtn);
  }
  
  for (var emoji in reactionsHash) {
    var count = reactionsHash[emoji];
    var reactionEl = document.createElement('span');
    reactionEl.className = 'reaction';
    reactionEl.dataset.emoji = emoji;
    reactionEl.innerHTML = emoji + ' ' + count;
    reactionEl.onclick = (function(msgId, e) {
      return function() { toggleReaction(msgId, e); };
    })(messageId, emoji);
    reactionsEl.insertBefore(reactionEl, addBtn);
  }
}

function toggleReaction(messageId, emoji) {
  authFetch('/messages/' + messageId + '/reactions', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ reaction: { emoji: emoji } })
  })
  .catch(function(error) {
    console.error('Błąd toggle reakcji:', error);
  });
}

function showReactionPicker(messageId) {
  var picker = document.createElement('div');
  picker.className = 'reaction-picker';
  picker.style.position = 'absolute';
  picker.style.backgroundColor = '#2f3136';
  picker.style.padding = '8px';
  picker.style.borderRadius = '8px';
  picker.style.boxShadow = '0 4px 12px rgba(0,0,0,0.3)';
  picker.style.zIndex = '1000';
  
  var emojis = ['👍', '❤️', '😂', '😮', '😢', '😡'];
  emojis.forEach(function(emoji) {
    var btn = document.createElement('span');
    btn.style.cursor = 'pointer';
    btn.style.padding = '4px 8px';
    btn.style.borderRadius = '4px';
    btn.innerHTML = emoji;
    btn.onclick = function() {
      toggleReaction(messageId, emoji);
      document.body.removeChild(picker);
    };
    btn.onmouseover = function() { this.style.background = '#36393f'; };
    btn.onmouseout = function() { this.style.background = ''; };
    picker.appendChild(btn);
  });
  
  var rect = event.target.getBoundingClientRect();
  picker.style.top = (rect.bottom + window.scrollY) + 'px';
  picker.style.left = (rect.left + window.scrollX) + 'px';
  
  document.body.appendChild(picker);
  
  setTimeout(function() {
    document.addEventListener('click', function closePicker(e) {
      if (!picker.contains(e.target)) {
        document.body.removeChild(picker);
        document.removeEventListener('click', closePicker);
      }
    });
  }, 0);
}

function sendMessage() {
  var input = document.getElementById('messageInput');
  if (!input) return;
  
  if (currentDMUserId) {
    var content = input.value.trim();
    if (!content) return;
    if (content.length > 500) {
      alert('Wiadomość może mieć max 500 znaków');
      return;
    }
    
    var data = {
      recipient_id: currentDMUserId,
      content: content
    };
    
    authFetch('/direct_messages', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(data)
    })
    .then(function(response) {
      if (response.ok) {
        input.value = '';
      } else {
        return response.json().then(function(error) {
          alert('Błąd wysyłania: ' + (error.errors ? error.errors.join(', ') : 'Nieznany błąd'));
        });
      }
    })
    .catch(function(error) {
      console.error('Błąd wysyłania DM:', error);
      alert('Błąd połączenia z serwerem');
    });
    return;
  }
  
  if (!currentChatServerId) return;
  
  var content = input.value.trim();
  if (!content) return;
  if (content.length > 500) {
    alert('Wiadomość może mieć max 500 znaków');
    return;
  }
  
  var data = {
    message: {
      content: content,
      username: currentUsername
    }
  };
  
  authFetch('/messages?chat_server_id=' + currentChatServerId, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(data)
  })
  .then(function(response) {
    if (response.ok) {
      input.value = '';
    }
  });
}

// ✅ FUNKCJA TWORZENIA PRZYCISKU WYLOGOWANIA (ZAWSZE WIDOCZNY)
function createLogoutButton() {
  const existing = document.getElementById('logoutButton');
  if (existing) existing.remove();
  
  const logoutBtn = document.createElement('button');
  logoutBtn.id = 'logoutButton';
  logoutBtn.innerHTML = '🚪 WYLOGUJ';
  logoutBtn.title = 'Wyloguj się';
  logoutBtn.style.cssText = `
    position: fixed;
    top: 15px;
    right: 15px;
    background: #f04747;
    color: white;
    border: none;
    padding: 10px 20px;
    border-radius: 25px;
    font-weight: bold;
    font-size: 16px;
    cursor: pointer;
    box-shadow: 0 4px 15px rgba(240, 71, 71, 0.5);
    z-index: 9999999;
    transition: all 0.2s;
  `;
  logoutBtn.onmouseover = function() { 
    this.style.transform = 'scale(1.05)';
    this.style.boxShadow = '0 6px 20px rgba(240, 71, 71, 0.8)';
  };
  logoutBtn.onmouseout = function() { 
    this.style.transform = 'scale(1)';
    this.style.boxShadow = '0 4px 15px rgba(240, 71, 71, 0.5)';
  };
  logoutBtn.addEventListener('click', logout);
  
  document.body.appendChild(logoutBtn);
  console.log('✅✅✅ PRZYCISK WYLOGOWANIA DODANY DO document.body! ✅✅✅');
}

// ✅ FUNKCJA WYLOGOWANIA
function logout() {
  const logoutBtn = document.getElementById('logoutButton');
  if (logoutBtn) logoutBtn.remove();
  
  fetch('/logout', {
    method: 'DELETE',
    credentials: 'include'
  })
  .then(function(response) {
    if (!response.ok) {
      throw new Error('Błąd wylogowania na serwerze');
    }
    
    localStorage.removeItem('auth_token');
    localStorage.removeItem('user_data');
    
    currentUserId = null;
    currentUsername = '';
    currentUserIsAdmin = false;
    currentChatServerId = null;
    currentDMUserId = null;
    
    if (subscription) { subscription.unsubscribe(); subscription = null; }
    if (dmSubscription) { dmSubscription.unsubscribe(); dmSubscription = null; }
    if (cable) { cable.disconnect(); cable = null; }
    
    const authContainer = document.getElementById('authContainer');
    const discordApp = document.getElementById('discordApp');
    if (authContainer && discordApp) {
      authContainer.style.display = 'flex';
      discordApp.style.display = 'none';
    }
    
    const messagesEl = document.getElementById('messages');
    if (messagesEl) messagesEl.innerHTML = '';
    
    alert('✅ Zostałeś wylogowany!');
  })
  .catch(function(error) {
    console.error('Błąd wylogowania:', error);
    alert('Błąd podczas wylogowywania: ' + error.message);
  });
}

// ✅ FUNKCJA DLA PROWADZĄCEGO
window.decryptDMInConsole = function(encryptedText) {
  console.log('ℹ️ Wiadomości prywatne w tym projekcie są chronione przez HTTPS (transport encryption).');
  console.log('ℹ️ Prawdziwe szyfrowanie end-to-end (E2EE) nie jest zaimplementowane z powodu złożoności.');
  console.log('ℹ️ Dane w bazie są chronione przez standardowe mechanizmy Rails.');
  return encryptedText;
};

console.log('💡 decryptDMInConsole("tekst") - informacja o zabezpieczeniach');