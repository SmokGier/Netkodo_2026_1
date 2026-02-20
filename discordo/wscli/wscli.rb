#!/usr/bin/env ruby
# -*- coding: utf-8 -*-

require 'websocket-client-simple'
require 'httparty'
require 'json'
require 'thread'

HOST = 'localhost'
PORT = 3000
WS_URL = "ws://#{HOST}:#{PORT}/cable"
API_URL = "http://#{HOST}:#{PORT}"

$current_user = nil
$ws = nil
$running = true

def login
  print "\nNazwa użytkownika: "
  username = gets.chomp.strip
  print "Hasło: "
  password = gets.chomp.strip
  
  response = HTTParty.post(
    "#{API_URL}/login",
    body: { username: username, password: password }.to_json,
    headers: { 'Content-Type' => 'application/json' }
  )
  
  if response.code == 200 && response.parsed_response['success']
    puts "✅ Zalogowano jako: #{username}"
    $current_user = username
    return true
  else
    puts "❌ Błąd logowania: #{response.parsed_response['error']}"
    return false
  end
end

def register
  print "\nNazwa użytkownika (2-20 znaków): "
  username = gets.chomp.strip
  print "Hasło (min. 6 znaków): "
  password = gets.chomp.strip
  print "Powtórz hasło: "
  password_confirm = gets.chomp.strip
  
  return false if password != password_confirm || password.length < 6
  
  response = HTTParty.post(
    "#{API_URL}/users",
    body: { 
      user: { 
        username: username, 
        password: password, 
        password_confirmation: password_confirm 
      } 
    }.to_json,
    headers: { 'Content-Type' => 'application/json' }
  )
  
  if response.code == 201 && response.parsed_response['success']
    puts "✅ Zarejestrowano jako: #{username}"
    $current_user = username
    return true
  else
    puts "❌ Błąd rejestracji: #{response.parsed_response['errors']}"
    return false
  end
end

def connect_websocket
  puts "\n🔌 Łączenie z WebSocket: #{WS_URL}"
  
  begin
    $ws = WebSocket::Client::Simple.connect(WS_URL)
    
    # Subskrybuj kanał general
    subscribe_data = {
      command: "subscribe",
      identifier: { channel: "ChatChannel" }.to_json
    }
    $ws.send(subscribe_data.to_json)
    
    # Wątek nasłuchujący
    Thread.new do
      $ws.on(:message) do |msg|
        data = JSON.parse(msg.data)
        if data['action'] == 'new_message' && data['message']
          msg_data = data['message']
          next if msg_data['username'] == $current_user # pomiń własne wiadomości
          
          timestamp = Time.now.strftime('%H:%M:%S')
          content = msg_data['content']
          
          # Wykryj GIF
          if content.match?(/\.(gif|png|jpg|jpeg)$/i)
            puts "\n[#{timestamp}] #{msg_data['username'].blue}: [GIF] #{content.cyan}"
          else
            puts "\n[#{timestamp}] #{msg_data['username'].blue}: #{content}"
          end
        end
      end
      
      $ws.on(:open) do
        puts "✅ Połączono z WebSocket!"
      end
      
      $ws.on(:close) do
        puts "\n⚠️ WebSocket rozłączony"
        $running = false
      end
      
      $ws.on(:error) do |e|
        puts "\n❌ Błąd WebSocket: #{e}"
        $running = false
      end
    end
    
    sleep 0.5
    return true
    
  rescue => e
    puts "❌ Błąd połączenia: #{e.message}"
    return false
  end
end

def send_message(content)
  # Obsługa /giphy
  if content.start_with?('/giphy')
    query = content[7..-1].strip
    content = "/giphy #{query}" if query != ''
  end
  
  message_data = {
    message: {
      content: content,
      username: $current_user
    }
  }
  
  Thread.new do
    begin
      HTTParty.post(
        "#{API_URL}/messages",
        body: message_data.to_json,
        headers: { 'Content-Type' => 'application/json' }
      )
    rescue => e
      puts "\n❌ Błąd wysyłania: #{e.message}"
    end
  end
end

# Kolorowanie tekstu
class String
  def blue; "\e[34m#{self}\e[0m" end
  def cyan; "\e[36m#{self}\e[0m" end
  def green; "\e[32m#{self}\e[0m" end
  def red; "\e[31m#{self}\e[0m" end
end

# Główna pętla
puts "\n" + "╔════════════════════════════════════════╗".green
puts "║" + "    DISCORDO - KONSOLNY KLIENT WSCLI   ".center(40) + "║".green
puts "╚════════════════════════════════════════╝".green

# Logowanie/rejestracja
loop do
  print "\n[1] Zaloguj się  [2] Zarejestruj się  [3] Wyjdź\n> "
  choice = gets.chomp
  
  case choice
  when '1'
    break if login
  when '2'
    break if register
  when '3'
    puts "\n👋 Do zobaczenia!".green
    exit
  else
    puts "❌ Nieprawidłowy wybór!".red
  end
end

# Połącz z WebSocket
unless connect_websocket
  puts "\n❌ Nie udało się połączyć z serwerem.".red
  puts "💡 Upewnij się, że Rails działa na http://localhost:3000".yellow
  exit
end

# Główna pętla czatu
puts "\n" + "╔════════════════════════════════════════╗".cyan
puts "║" + "        WITAJ W CZACIE DISCORDO!       ".center(40) + "║".cyan
puts "║" + "   Wpisz wiadomość i naciśnij Enter    ".center(40) + "║".cyan
puts "║" + "   /giphy [zapytanie] - wyszukaj GIF   ".center(40) + "║".cyan
puts "║" + "   /exit - wyjdź z programu            ".center(40) + "║".cyan
puts "╚════════════════════════════════════════╝".cyan

while $running
  print "\n> "
  input = gets.chomp.strip
  
  case input
  when '/exit'
    puts "\n👋 Do zobaczenia!".green
    $ws.close if $ws
    exit
    
  when ''
    # Ignoruj puste wiadomości
    
  else
    # Wyświetl własną wiadomość lokalnie
    timestamp = Time.now.strftime('%H:%M:%S')
    puts "[#{timestamp}] #{$current_user.blue}: #{input.green}"
    
    # Wyślij do serwera
    send_message(input)
  end
end

# Obsługa Ctrl+C
trap('INT') do
  puts "\n\n👋 Przerwano przez użytkownika".yellow
  $ws.close if $ws
  exit
end
