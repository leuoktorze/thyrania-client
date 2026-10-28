@echo off
rem Abre o cliente 15.x guardando as configuracoes e o diagnostico do Auxiliador em .\userdata
rem (assim da para ler o thyrania_trace.txt e o log mesmo se o cliente travar)
cd /d "%~dp0"
start "" otclient_gl_x64.exe "--user-dir=%~dp0userdata"
