#!/usr/bin/env python

#####################################################
#  Install
#sudo pip3 install keyboard --break-system-packages
#sudo pip3 install picamera --break-system-packages
#sudo pip3 install python-can --break-system-packages
#####################################################
'''
            original script 
https://github.com/peetereczek/openauto-audi-api
'''



#####################################################
#  set here, what you want to have active
#  PLEASE ONLY USE 'true' or 'false'

#  MFSW (multi function steering wheel) will autodetect if it is installed

activate_rnse_tv_input = 'true'
control_pi_by_rns_e_buttons = 'true'

activate_rnsd_tv_input = 'false'
control_pi_by_rns_d_buttons = 'false'

control_pi_by_mfsw = 'true'
read_and_set_time_from_dis = 'true'

reversecamera_by_reversegear = 'false'

shutdown_by_ignition_off = 'false'
shutdown_by_pulling_key = 'false'

reversecamera_turn_off_delay = '5'  # in seconds
shutdown_delay = '5'  # in seconds

#####################################################

'''
Action\0=NONE LEFT
Action\1=enter ('RNS: Encoder Press            | Keyboard: "ENTER" | OpenAuto: "ENTER"')
Action\2=NONE RIGHT
Action\3=left  ('RNS: Button UP press          | Keyboard: "LEFT"  | OpenAuto: "UP"')
Action\4=right ('RNS: Button DOWN press        | Keyboard: "RIGHT" | OpenAuto: "DOWN"')
Action\5=back  ('RNS: Button RETURN press      | Keyboard: "BACK"  | OpenAuto: "BACK"')
Action\6=NONE Home
Action\7=c     ('RNSE: Button UP longpress     | Keyboard: "C"     | OpenAuto: "PHONE"')
Action\7=c     ('RNSD: Button PLUS(+) press    | Keyboard: "C"     | OpenAuto: "PHONE"')
Action\8=e     ('RNSE: Button RETURN longpress | Keyboard: "E"     | OpenAuto: "Call END"') 
Action\8=e     ('RNSD: Button MINUS(-) press   | Keyboard: "E"     | OpenAuto: "Call END"') 
Action\9=g     ('RNS not tv mode - play media  | Keyboard: "G"     | OpenAuto: "PLAY"')
Action\10=s    ('RNS tv mode - pause media     | Keyboard: "S"     | OpenAuto: "PAUSE"')
Action\11=b    ('RNS: Button PREV TRACK press  | Keyboard: "B"     | OpenAuto: "PREVIOUS TRACK"')
Action\12=n    ('RNS: Button NEXT TRACK press  | Keyboard: "N"     | OpenAuto: "NEXT TRACK"')
Action\13=p    ('RNSE: Encoder press longpress | Keyboard: "P"     | OpenAuto: "TOGLE PLAY"')
Action\14=v    ('RNSE: Button SETUP press      | Keyboard: "V"     | OpenAuto: "VOICE"')
Action\14=v    ('RNSD: Button AS press         | Keyboard: "V"     | OpenAuto: "VOICE"')
Action\15=up   ('RNS: Encoder scrolled LEFT    | Keyboard: "UP"    | OpenAuto: "Scroll DOWN"')	
Action\16=down ('RNS: Encoder scrolled RIGHT   | Keyboard: "DOWN"  | OpenAuto: "Scroll UP"')
Action\17=d    ('RNSE: Button DOWN longpress   | Keyboard: "D"     | OpenAuto: "Togle Dark Mode"')
Action\17=d    ('RNSD: Button TONE+AM          | Keyboard: "D"     | OpenAuto: "Togle Dark Mode"')
Action\18=NONE decrease Brightness
Action\19=NONE increase Brightness
Action\20=NONE Decrease Volume
Action\21=NONE Increase Volume
Action\22=f    ('RNSE: Button DOWN longpress   | Keyboard: "F"     | OpenAuto: "Toggle Fullscreen"')
Action\22=f    ('RNSD: Button SETUP            | Keyboard: "F"     | OpenAuto: "Toggle Fullscreen"') 
Action\23=NONE Show AA Page
Action\24=NONE Show Media Page
Action\25=NONE Show Vehicle Page
Action\26=NONE Show Camera Page
Action\27=NONE Show Launcher Page
Action\28=NONE Show Settings
Action\29=NONE Cycle Page
               ("RNS-E:  Button SETUP longpress | shutting down raspberry pi")
'''
