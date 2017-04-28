net stop LanmanServer /yes
timeout /t 10
sc config LanmanServer start= disabled
