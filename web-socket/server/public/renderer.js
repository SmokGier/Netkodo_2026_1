// Get server URL dynamically (works for localhost and network access)
const PROTOCOL = window.location.protocol;
const HOST = window.location.hostname;
const PORT = window.location.port || '3000';
const CABLE_URL = `${PROTOCOL}//${HOST}:${PORT}/cable`;
const API_BASE = `${PROTOCOL}//${HOST}:${PORT}`;

const CHANNEL_NAME = "TasksChannel";
const logEl = document.getElementById('log');
const statusEl = document.getElementById('status');
const tasksEl = document.getElementById('tasks');

function log(msg, cls='') {
  const div = document.createElement('div');
  div.className = cls;
  div.textContent = `[${new Date().toLocaleTimeString()}] ${msg}`;
  logEl.prepend(div);
  console.log(msg);
}

log(`🔌 Łączenie z: ${CABLE_URL}`);

const cable = ActionCable.createConsumer(CABLE_URL);
cable.subscriptions.create(CHANNEL_NAME, {
  connected() {
    statusEl.textContent = "✅ Połączono!";
    statusEl.className = "connected";
    log("Połączono z serwerem", "connected");
    fetchTasks();
  },
  disconnected() { 
    statusEl.textContent = "⚠️ Rozłączono"; 
    statusEl.className = "error"; 
    log("Rozłączono", "error"); 
  },
  rejected() { 
    statusEl.textContent = "❌ Błąd połączenia"; 
    statusEl.className = "error"; 
    log("Subskrypcja odrzucona", "error"); 
  },
  received(data) {
    log("📩 Otrzymano dane", "received");
    setTimeout(fetchTasks, 300);
  }
});

async function fetchTasks() {
  try {
    const res = await fetch(`${API_BASE}/tasks`);
    const tasks = await res.json();
    tasksEl.innerHTML = tasks.length === 0 
      ? '<p style="color:#94a3b8">Brak zadań</p>'
      : tasks.map(t => `
        <div class="task ${t.completed ? 'completed' : ''}">
          <strong>${t.title}</strong><br>
          <small>${t.description || ''} | ${t.completed ? '✓ Zrobione' : '○ W trakcie'}</small><br>
          <div style="margin-top:8px">
            <button onclick="toggleCompleted(${t.id}, ${t.completed})" style="background:${t.completed ? '#64748b' : '#10b981'}; color:white; border:none; padding:6px 12px; border-radius:4px; margin-right:5px;">
              ${t.completed ? '↺ Cofnij' : '✓ Zrobione'}
            </button>
            <button onclick="deleteTask(${t.id})" style="background:#ef4444; color:white; border:none; padding:6px 12px; border-radius:4px;">🗑️ Usuń</button>
          </div>
        </div>
      `).join('');
  } catch (e) {
    tasksEl.innerHTML = '<p style="color:#f87171">Serwer nie działa!</p>';
    log("Błąd: " + e.message, "error");
  }
}

async function addTask() {
  const title = document.getElementById('task-title').value.trim();
  const description = document.getElementById('task-description').value.trim();
  if (!title) { alert('⚠️ Tytuł jest wymagany!'); return; }
  try {
    await fetch(`${API_BASE}/tasks`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ task: { title, description, completed: false } })
    });
    log("✅ Dodano: " + title, "received");
    document.getElementById('task-title').value = '';
    document.getElementById('task-description').value = '';
    fetchTasks();
  } catch (e) {
    log("Błąd: " + e.message, "error");
    alert("❌ Nie udało się dodać!");
  }
}

async function toggleCompleted(id, currentCompleted) {
  const newStatus = !currentCompleted;
  try {
    await fetch(`${API_BASE}/tasks/${id}`, {
      method: 'PATCH',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ task: { completed: newStatus } })
    });
    log(`✅ ${newStatus ? 'Oznaczono jako ZROBIONE' : 'Cofnięto status'} zadanie #${id}`, "received");
  } catch (e) {
    log("Błąd aktualizacji: " + e.message, "error");
    alert("❌ Nie udało się zaktualizować!");
  }
}

async function deleteTask(id) {
  if (!confirm('Czy na pewno usunąć to zadanie?')) return;
  try {
    await fetch(`${API_BASE}/tasks/${id}`, { method: 'DELETE' });
    log(`🗑️ Usunięto zadanie #${id}`, "received");
  } catch (e) {
    log("Błąd usuwania: " + e.message, "error");
    alert("❌ Nie udało się usunąć!");
  }
}
