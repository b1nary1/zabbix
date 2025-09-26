$ffmpegOutput = & "C:\ffmpeg\bin\ffmpeg.exe" -hide_banner -f dshow -i audio="Analogue 1 + 2 (2- Focusrite USB Audio)" -t 12 -af "pan=mono|c0=c1,astats=metadata=1:reset=0" -f null - 2>&1
$ffmpegOutput -join "`n"
