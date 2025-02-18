#!/usr/bin/env python

from __future__ import print_function
import os
import sys
import binascii
import re
import can
from time import sleep

import keyboard

# import config
# from config import activate_rnse_tv_input, control_pi_by_rns_e_buttons
# from config import activate_rnsd_tv_input, control_pi_by_rns_d_buttons
# from config import control_pi_by_mfsw, read_and_set_time_from_dis
# from config import reversecamera_by_reversegear, shutdown_by_ignition_off, shutdown_by_pulling_key
# from config import reversecamera_turn_off_delay, shutdown_delay
#####################################################
#  Install
#sudo pip3 install keyboard --break-system-packages
#sudo pip3 install picamera --break-system-packages
#sudo pip3 install python-can --break-system-packages

#  set here, what you want to have active
#  PLEASE ONLY USE 'true' or 'false'

#  MFSW (multi function steering wheel) will autodetect if it is installed

activate_rnse_tv_input = 'true'
control_pi_by_rns_e_buttons = 'true'
control_pi_by_mfsw = 'true'
read_and_set_time_from_dis = 'true'
reversecamera_by_reversegear = 'false'
shutdown_by_ignition_off = 'false'
shutdown_by_pulling_key = 'false'
reversecamera_turn_off_delay = '5'  # in seconds
shutdown_delay = '5'  # in seconds


#####################################################

bus = can.Bus(interface='socketcan', channel='can0', receive_own_messages=True)

if activate_rnse_tv_input == 'true':
    os.system('cansend can0 602#8912300000000000')
    print('TV INPUT for RNS-E')


print('script starting')
# deactivate camera functions if there is an error importing picamera - script doesn't crash then
if reversecamera_by_reversegear == 'true':
    try:
        from picamera import PiCamera
    except ModuleNotFoundError as e:
        print('picamera ist not installed - is not installed - please connect the pi to the internet and install picamera with "pip3 install picamera" and "sudo pip3 install picamera"')
    except ImportError as e:
        reversecamera_by_reversegear = 'false'
        pass
    try:
        camera = PiCamera()
    except Exception as e:
        print("camera is not connected or has problems - disabling all reversecamera features")
        reversecamera_by_reversegear = 'false'  # deactivate reversecamera features if the camera is not working
        pass

def button_controls():
    try:
        tmset = 0
        carmodel = ''
        car_model_set = 0
        tv_mode_active = 1
        mfsw_detected = 0
        press_mfsw = 0
        up = 0
        down = 0
        select = 0
        back = 0
        nextbtn = 0
        prev = 0
        setup = 0
        for message in bus:
            canid = str(hex(message.arbitration_id).lstrip('0x').upper())
            msg = binascii.hexlify(message.data).decode('ascii').upper()
            # read carmodel (8E - Audi A4 / 8P - Audi A3) and caryear - precondition to use different can ids
            if canid == '65F':
                if msg[0:2] == '01':
                    if car_model_set == 0:
                        msg = re.sub('[\\s+]', '', msg)
                        carmodel = msg[8:12]
                        carmodelyear = msg[14:16]
                        carmodel = bytes.fromhex(carmodel).decode()
                        carmodelyear = bytes.fromhex(carmodelyear).decode()
                        carmodelyear = str(int(carmodelyear, 16) + 2000)
                        car_model_set = 1
                        print('car model and carmodel year was successfully read from canbus')
                        print("car model:", carmodel)
                        print("car model year:", carmodelyear)

            # read time from dis (driver information system) and set the time on raspberry pi.
            elif canid == '623':
                if read_and_set_time_from_dis == 'true':  # read date and time from dis and set on raspberry pi
                    if tmset == 0:
                        msg = re.sub('[\\s+]', '', msg)
                        date = 'sudo date %s%s%s%s%s.%s' % (
                            msg[10:12], msg[8:10], msg[2:4], msg[4:6], msg[12:16], msg[6:8])
                        os.system(date)
                        print('Date and time set on raspberry pi')
                        tmset = 1

            elif canid == '661':
                if activate_rnse_tv_input == 'true':  # Send message to activate RNS-E tv input
                    os.system('cansend can0 602#8912300000000000')
                    print("activate rns-e tv input message sent")
                    #elif msg == '8101123700000000' or msg == '8301123700000000':
                    
                elif msg[6:8] != '37':
                    if tv_mode_active == 0:
                        keyboard.press('s')  # pause media, if rns-e left tv mode
                        keyboard.release('s')
                        print('RNS is not tv mode | pause media | Keyboard: "S" | OpenAuto: "pause"')
                        tv_mode_active = 1
                else:
                    if tv_mode_active == 1:
                        keyboard.press('g')  # play media, if rns-d ist (back) on tv mode
                        keyboard.release('g')
                        print('RNS tv mode | play media | Keyboard: "G"  | OpenAuto: "play"')
                        tv_mode_active = 0

            # read mfsw button presses if mfsw ist detected and rns-e tv input is active
            elif canid == '5C3' and control_pi_by_mfsw == 'true':
                if mfsw_detected == 0:
                    mfsw_detected = 1
                    print('mfsw detected')

                # read message 3900 or 3A00 on can id 5C3 to detect if a mfsw is installed.
                elif mfsw_detected == 1 and tv_mode_active == 1:
                    if (carmodel == '8E' and msg == '3904') or (carmodel == '8P' and msg == '390B') or (carmodel == '8J' and msg == '390B'):
                        keyboard.press('up')
                        keyboard.release('up')
                        print("MFSW " + str(carmodel) + ": scan wheel UP - Keyboard: 'UP' - OpenAuto: Scroll UP")
                        press_mfsw = 0

                    elif (carmodel == '8E' and msg == '3905') or (carmodel == '8P' and msg == '390C') or (carmodel == '8J' and msg == '390C'):
                        keyboard.press('down')
                        keyboard.release('down')
                        print("MFSW " + str(carmodel) + ": scan wheel DOWN - Keyboard: 'DOWN' - OpenAuto: Scroll DOWN")
                        press_mfsw = 0

                    elif (carmodel == '8E' and msg == '3908') or (carmodel == '8P' and msg == '3908') or (carmodel == '8J' and msg == '3908'):
                        press_mfsw += 1
                    elif (msg == '3900' or msg == '3A00') and press_mfsw > 0:
                        if press_mfsw == 1:
                            keyboard.press('enter')
                            keyboard.release('enter')
                            print("MFSW " + str(carmodel) + ": scan wheel shortpress - Keyboard: 'ENTER' on keyboard- OpenAuto: ENTER")
                            press_mfsw = 0
                        elif press_mfsw >= 2:
                            keyboard.press('backspace')
                            keyboard.release('backspace')
                            print("MFSW " + str(carmodel) + ": scan wheel longpress - Keyboard 'BACKSPACE' - OpenAuto: BACK") #B returne
                            press_mfsw = 0
                    elif msg == '3900' and press_mfsw == 0:
                        nextbtn = 0
                        prev = 0

            # read reverse gear message to activate the reverse camera
            elif canid == '351':
                if reversecamera_by_reversegear == 'true':  # read reverse gear message and start reversecamera
                    if msg[0:2] == '00' and gear == 1:
                        gear = 0
                        print("forward gear engaged - stopping reverse camera with", reversecamera_turn_off_delay, "seconds delay")
                        sleep(int(reversecamera_turn_off_delay))  # turn camera off with 5 seconds delay
                        camera.stop_preview()
                    elif msg[0:2] == '02' and gear == 0:
                        gear = 1
                        print("reverse gear engaged - starting reverse camera")
                        camera.start_preview()

            # read RNS-E button presses to control Raspberry Pi/OpenAuto Pro
            elif canid == '461':
                if control_pi_by_rns_e_buttons == 'true': # read can messages from rns-e button presses
                    if msg == '373001004001':  #R.Encoder.Left
                        keyboard.press('up')
                        keyboard.release('up')
                        print('Encoder scrolled LEFT  | Keyboard: "UP" | OpenAuto: "Scroll DOWN"')

                    elif msg == '373001002001':  #R.Encoder.Right
                        keyboard.press('down')
                        keyboard.release('down')
                        print('Encoder scrolled RIGHT | Keyboard: "DOWN" | OpenAuto: "Scroll UP"')

                    elif msg == '373001001000':  # RNS-E: wheel pressed
                        select += 1
                    elif msg == '373004001000' and select > 0:  # RNS-E: wheel released
                        if select <= 4:
                            keyboard.press('enter')
                            keyboard.release('enter')
                            print('RNS: Encoder Press | Keyboard: "ENTER" | OpenAuto: "ENTER"')
                            select = 0
                        elif select > 4:
                            keyboard.press('p')
                            keyboard.release('p')
                            print('RNSE: Encoder press longpress | Keyboard: "P" | OpenAuto: "TOGLE PLAY"')
                            select = 0

                    elif msg == '373001400000':  #RNS-E: button UP pressed
                        up += 1
                    elif msg == '373004400000' and up > 0:  # RNS-E: button UP release
                        if up <= 4:
                            keyboard.press('left')
                            keyboard.release('left')
                            print('Button UP press | Keyboard: "LEFT" | OpenAuto: "UP"')
                            up = 0
                        elif up > 4:
                            keyboard.press('c')
                            keyboard.release('c')
                            print('RNSE: Button UP longpress | Keyboard: "C" | OpenAuto: "PHONE"')
                            up = 0

                    elif msg == '373001800000':  # RNS-E: button DOWN pressed
                        down += 1
                    elif msg == '373004800000' and down > 0:  # RNS-E: button DOWN released
                        if down <= 4:
                            keyboard.press('right')
                            keyboard.release('right')
                            print('Button DOWN press | Keyboard: "RIGHT" | OpenAuto: "DOWN"')
                            down = 0
                        elif down > 4: # just react if function is enabled by user
                            keyboard.press('d')
                            keyboard.release('d')
                            print('RNSE: Button DOWN longpress | Keyboard: "D" | OpenAuto: "Togle Dark Mode"')
                            down = 0

                    elif msg == '373001000200':  # RNS-E: return button pressed
                        back += 1
                    elif msg == '373004000200' and back > 0:  # RNS-E: return button released
                        if back <= 4:
                            keyboard.press('b')
                            keyboard.release('b')
                            print('RNS: Button RETURN press | Keyboard: "BACKSPACE" | OpenAuto: "BACK"')
                            back = 0
                        elif back > 4:
                            keyboard.press('e')
                            keyboard.release('e')
                            print('RNSE: Button RETURN longpress | Keyboard: "E" | OpenAuto: "Call END"') 
                            back = 0

                    elif msg == '373001020000':  # RNS-E: next track button pressed
                        nextbtn += 1
                    elif msg == '373004020000' and nextbtn > 0:  # RNS-E: next track button released
                        if nextbtn <= 4:
                            keyboard.press('n')
                            keyboard.release('n')
                            print('RNS: Button NEXT TRACK press | Keyboard: "N" | OpenAuto: "NEXT TRACK"')
                            nextbtn = 0
                        elif nextbtn > 4:
                            keyboard.press('a')
                            keyboard.press('a')
                            print('RNS-E:   Button NEXT TRACK longpress - Keyboard: "A" - OpenAuto: "Toggle application"')
                            nextbtn = 0

                    elif msg == '373001010000':  # RNS-E: previous track button pressed
                        prev += 1
                    elif msg == '373004010000' and prev > 0: # RNS-E: previous track button released
                        if prev <= 4:
                            keyboard.press('b')
                            keyboard.release('b')
                            print('RNS: Button PREV TRACK press | Keyboard: "B" | OpenAuto: "PREVIOUS TRACK"')
                            prev = 0
                        elif prev > 4:
                            keyboard.press('u')
                            keyboard.release('u')
                            print('RNS-E:   Button PREV TRACK longpress - Keyboard: "U" - OpenAuto: "Bring OpenAuto Pro to front"')
                            prev = 0

                    elif msg == '373001000100':  # RNS-E: setup button pressed
                        setup += 1
                    elif msg == '373004000100' and setup > 0:  # RNS-E: setup button released
                        if setup <= 6:
                            keyboard.press('v')
                            keyboard.release('v')
                            print('RNSE: Button SETUP press    | Keyboard: "V" | OpenAuto: "VOICE"')
                            setup = 0
                        elif setup > 6:
                            print("RNSE: Button SETUP longpress | shutting down raspberry pi")
                            os.system('sudo shutdown -h now')
                            setup = 0

 
            # read ignition message, or pulling key message to shut down the raspberry pi
            elif canid == '271':
                if shutdown_by_ignition_off == 'true' or shutdown_by_pulling_key == 'true':
                    if msg[0:2] == '11' and shutdown_by_ignition_off == 'true':
                        print("ignition off message detected - system will shutdown in", shutdown_delay, "seconds")
                        sleep(
                            int(shutdown_delay))  # defined delay to shutdown the pi
                        print("system is shutting down now")
                        os.system('sudo shutdown -h now')
                    elif msg[0:2] == '10' and shutdown_by_pulling_key == 'true':
                        print("pulling key message detected - system will shutdown in", shutdown_delay, "seconds")
                        sleep(
                            int(shutdown_delay))  # defined delay to shutdown the pi
                        print("system is shutting down now")
                        os.system('sudo shutdown -h now')

    except Exception as e:
        print("error in function read_from_canbus:", str(e))

    except KeyboardInterrupt as e:
        if reversecamera_by_reversegear == 'true':
            camera.stop_preview()
            camera.close()
        print("Script killed by KeyboardInterrupt!")
        exit(1)
        
button_controls()

