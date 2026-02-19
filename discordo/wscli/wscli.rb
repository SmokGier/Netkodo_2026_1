#!/usr/bin/env ruby
# -*- coding: utf-8 -*-

require 'websocket-client-simple'
require 'json'
require 'colorize'
require 'thread'
require 'httparty'

class DiscordoCLI
  attr_accessor :ws, :current_username, :current_server_id, :connected
  
  def initialize(host = 'localhost', port = 3000)
    @host = host
    @port = port
    @connected = false
    @current_username = nil
    @current_server_id = nil
    @ws = nil
    @running = true
  end
  
  def login
    puts "\n" + "╔════════════════════════════════════════╗".yellow
    puts "║" + "         DISCORDO - LOGIN".center(40) + "║".yellow
    puts "╚════════════════════════════════════════╝".yellow
    
    print "\nNazwa użytkownika: ".cyan
    username = gets.chomp
    
    print "Hasło: ".cyan
    password = gets.chomp
    
    response = HTTParty.post(
      "http://#{@host}:#{@port}/login",
      body: { username: username, password: password }.to_json,
      headers: { 'Content-Type' => 'application/json' }
    )
    
    if response.code == 200 && response.parsed_response['success']
      @current_username = username
      puts "\n✅ " + "Zalogowano jako: #{username}".green
      return true
    else
      puts "\n❌ " + "Błąd logowania: #{response.parsed_response['error'] || 'Nieznany błąd'}".red
      return false
    end
  end
  
  def register
    puts "\n" + "╔════════════════════════════════════════╗".yellow
    puts "║" + "      DISCORDO - REJESTRACJA".center(40) + "║".yellow
    puts "╚════════════════════════════════════════╝".yellow
    
    print "\nNazwa użytkownika (2-20 znaków): ".cyan
    username = gets.chomp
    
    print "Hasło (min. 6 znaków): ".cyan
    password = gets.chomp
    
    print "Powtórz hasło: ".cyan
    password_confirm = gets.chomp
    
    if password != password_confirm
      puts "\n❌ " + "Hasła nie są identyczne!".red
      return false
    end
    
    if password.length < 6
      puts "\n❌ " + "Hasło musi mieć min. 6 znaków!".red
      return false
    end
    
    response = HTTParty.post(
      "http://#{@host}:#{@port}/users",
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
      @current_username = username
      puts "\n✅ " + "Zarejestrowano jako: #{username}".green
      return true
    else
      errors = response.parsed_response['errors'] || ['Nieznany błąd']
      puts "\n❌ " + "Błąd rejestracji: #{errors.join(', ')}".red
      return false
    end
  end
  
  def connect_websocket
    ws_url = "ws://#{@host}:#{@port}/cable"
    
    puts "\n🔌 " + "Łączenie z WebSocket: #{ws_url}".cyan
    
    begin
      # Zapisz self dla callbacków
      cli = self
      
      # Połącz się z WebSocket
      @ws = WebSocket::Client::Simple.connect(ws_url)
      
      # Handler wiadomości
      @ws.on(:message) do |msg|
        cli.handle_message(msg)
      end
      
      # Handler otwarcia połączenia
      @ws.on(:open) do
        puts "\n✅ " + "Połączono z WebSocket!".green
        cli.connected = true
        cli.subscribe_to_channel
      end
      
      # Handler zamknięcia
      @ws.on(:close) do |e|
        puts "\n⚠️ " + "WebSocket rozłączony: #{e}".yellow
        cli.connected = false
      end
      
      # Handler błędów
      @ws.on(:error) do |e|
        puts "\n❌ " + "Błąd WebSocket: #{e}".red
      end
      
      # Czekaj na połączenie
      timeout = 5
      while !@connected && timeout > 0
        sleep 0.5
        timeout -= 0.5
      end
      
      if @connected
        return true
      else
        puts "\n❌ " + "Timeout połączenia z WebSocket!".red
        return false
      end
      
    rescue => e
      puts "\n❌ " + "Błąd połączenia: #{e.message}".red
      return false
    end
  end
  
  def subscribe_to_channel
    identifier = @current_server_id ? 
      { channel: "ChatChannel", chat_server_id: @current_server_id } :
      { channel: "ChatChannel" }
    
    subscription_data = {
      command: "subscribe",
      identifier: identifier.to_json
    }
    
    @ws.send(subscription_data.to_json)
    puts "\n📡 " + "Subskrybowano kanał!".cyan
  end
  
  def list_servers
    puts "\n" + "╔════════════════════════════════════════╗".yellow
    puts "║" + "         SERWERY DOSTĘPNE".center(40) + "║".yellow
    puts "╚════════════════════════════════════════╝".yellow
    
    response = HTTParty.get("http://#{@host}:#{@port}/chat_servers")
    
    if response.code == 200
      servers = response.parsed_response
      
      if servers.empty?
        puts "\nℹ️ " + "Brak dostępnych serwerów".yellow
        puts "💡 Utwórz serwer przez przeglądarkę: http://localhost:3000/discordo".yellow
        return
      end
      
      puts "\nDostępne serwery:"
      servers.each_with_index do |server, index|
        lock_icon = server['private'] ? '🔒' : '🔓'
        puts "#{index + 1}. #{lock_icon} #{server['name']} (ID: #{server['id']})"
      end
      
      print "\nWybierz serwer (lub 0 dla #general): ".cyan
      choice = gets.chomp.to_i
      
      if choice == 0
        @current_server_id = nil
        subscribe_to_channel
        puts "\n✅ " + "Wybrano kanał #general".green
      elsif choice > 0 && choice <= servers.length
        selected = servers[choice - 1]
        
        if selected['private']
          print "Wprowadź hasło: "
          password = gets.chomp.strip
          
          response = HTTParty.post(
            "http://#{@host}:#{@port}/chat_servers/#{selected['id']}/join",
            body: { password: password }.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )
          
          if response.code != 200
            puts "\n❌ " + "Nieprawidłowe hasło!".red
            return
          end
        end
        
        @current_server_id = selected['id']
        subscribe_to_channel
        puts "\n✅ " + "Dołączono do serwera: #{selected['name']}".green
      else
        puts "\n❌ " + "Nieprawidłowy wybór!".red
      end
    else
      puts "\n❌ " + "Błąd ładowania serwerów (kod: #{response.code})".red
      puts "💡 Sprawdź czy serwer Rails działa na http://localhost:3000".yellow
    end
  end
  
  def send_message(content)
    # Obsługa komendy /giphy
    if content.start_with?('/giphy')
      # Wiadomość zostanie wysłana jako zwykła treść - backend obsłuży komendę
    end
    
    message_data = {
      message: {
        content: content,
        username: @current_username
      }
    }
    
    if @current_server_id
      message_data[:message][:chat_server_id] = @current_server_id
    end
    
    Thread.new do
      begin
        response = HTTParty.post(
          "http://#{@host}:#{@port}/messages",
          body: message_data.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )
        
        if response.code != 201
          puts "\n❌ " + "Błąd wysyłania: #{response.parsed_response['error'] || 'Nieznany błąd'}".red
        end
      rescue => e
        puts "\n❌ " + "Błąd połączenia: #{e.message}".red
      end
    end
  end
  
  def handle_message(msg)
    begin
      data = JSON.parse(msg.data)
      
      case data['action']
      when 'new_message'
        message = data['message']
        return unless message
        
        username = message['username'] || 'Anonim'
        content = message['content'] || ''
        
        # Pomijaj własne wiadomości (są już wyświetlane przy wysyłaniu)
        return if username == @current_username
        
        timestamp = Time.now.strftime('%H:%M:%S')
        
        # Wykryj czy to GIF
        if content.match?(/\.(gif|png|jpg|jpeg)$/i)
          puts "\n[#{timestamp}] ".cyan + "#{username}: ".yellow + "[GIF] #{content}"
        else
          puts "\n[#{timestamp}] ".cyan + "#{username}: ".yellow + content
        end
        
      when 'update_reactions'
        # Ignoruj dla uproszczenia
        
      when 'typing'
        username = data['username'] || 'Ktoś'
        is_typing = data['is_typing']
        
        if is_typing
          puts "\n⌨️  #{username} pisze...".yellow
        end
        
      else
        # puts "\nℹ️  Otrzymano: #{data['action']}".cyan
      end
      
    rescue JSON::ParserError
      # Ignoruj nieparsowalne wiadomości
    rescue => e
      puts "\n⚠️  Błąd: #{e.message}".yellow
    end
  end
  
  def show_help
    puts "\n" + "╔════════════════════════════════════════╗".yellow
    puts "║" + "           KOMENDY WSCLI".center(40) + "║".yellow
    puts "╚════════════════════════════════════════╝".yellow
    puts "\n/help".cyan + "    - Pokaż tę pomoc"
    puts "/servers".cyan + "  - Lista serwerów"
    puts "/general".cyan + "  - Wróć do kanału #general"
    puts "/giphy X".cyan + "  - Wyszukaj GIF (np. /giphy koty)"
    puts "/exit".cyan + "    - Wyjdź z programu"
    puts "\nWpisz wiadomość i naciśnij Enter aby wysłać".yellow
  end
  
  def run
    puts "\n" + "╔════════════════════════════════════════╗".yellow
    puts "║" + "      DISCORDO WEBSOCKET CLIENT".center(40) + "║".yellow
    puts "║" + "          Wersja 1.0".center(40) + "║".yellow
    puts "╚════════════════════════════════════════╝".yellow
    
    # Login or register
    loop do
      print "\n[1] Zaloguj się  [2] Zarejestruj się  [3] Wyjdź\n".cyan
      print "> ".cyan
      choice = gets.chomp
      
      case choice
      when '1'
        break if login
      when '2'
        break if register
      when '3'
        puts "\n👋 Do zobaczenia!".yellow
        exit
      else
        puts "\n❌ Nieprawidłowy wybór!".red
      end
    end
    
    # Connect to WebSocket
    unless connect_websocket
      puts "\n❌ Nie udało się połączyć z WebSocket!".red
      puts "💡 Upewnij się, że serwer Rails działa na http://localhost:3000".yellow
      exit
    end
    
    # Main loop
    show_help
    
    loop do
      print "\n> ".green
      
      input = gets.chomp.strip
      
      case input
      when '/help'
        show_help
        
      when '/servers'
        list_servers
        
      when '/general'
        @current_server_id = nil
        subscribe_to_channel
        puts "\n✅ " + "Wrócono do #general".green
        
      when '/exit'
        puts "\n👋 Do zobaczenia!".yellow
        @ws.close if @ws
        exit
        
      when '/giphy'
        print "Wyszukaj GIF: ".cyan
        query = gets.chomp.strip
        send_message("/giphy #{query}") if query != ''
        
      when /^\/giphy\s+(.+)$/
        send_message(input)
        
      when ''
        # Ignore empty input
        
      else
        # Wyświetl własną wiadomość lokalnie
        timestamp = Time.now.strftime('%H:%M:%S')
        puts "[#{timestamp}] ".cyan + "#{@current_username}: ".blue + input
        
        # Wyślij do serwera
        send_message(input)
      end
    end
    
  rescue Interrupt
    puts "\n\n👋 Przerwano przez użytkownika".yellow
    @ws.close if @ws
    exit
  rescue => e
    puts "\n❌ Błąd: #{e.message}".red
    puts e.backtrace.first(5) if ENV['DEBUG']
    @ws.close if @ws
    exit
  end
end

# Main execution
if __FILE__ == $0
  # Sprawdź czy gemy są zainstalowane
  begin
    require 'websocket-client-simple'
    require 'colorize'
    require 'httparty'
  rescue LoadError => e
    puts "\n❌ Brak wymaganych gemów: #{e.message}".red
    puts "💡 Uruchom: bundle install".yellow
    exit 1
  end
  
  cli = DiscordoCLI.new('localhost', 3000)
  cli.run
end
