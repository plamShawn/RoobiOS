#!/usr/bin/python

import queue
import threading
from select import select

q = queue.Queue()

def get_key_event(q: queue):
    from evdev import InputDevice, categorize, ecodes
    # 打开输入设备
    # dev = InputDevice('/dev/input/event2')
    power_event = [0, 1, 2]
    devices = []
    for i in power_event:
        try:
            devices.append(InputDevice(f'/dev/input/event{i}'))
        except FileNotFoundError:
            pass
    pri = 0
    times = 0
    while True:
        r, w, x = select(devices, [], [])
        for dev in r:
            for event in dev.read():
                if event.type == ecodes.EV_KEY:
                    key_state = categorize(event)
                    key_code = key_state.keycode

                    if key_state.keystate == key_state.key_down and key_code == "KEY_POWER":
                        q.put(1)

tr = threading.Thread(target=get_key_event, args=(q,))
tr.setDaemon(True)
tr.start()


for i in range(10,0, -1):
    print(i, flush=True)
    try:
        q.get(timeout=1)
        exit(0)
    except queue.Empty:
        ...

print("超时")
exit(1)