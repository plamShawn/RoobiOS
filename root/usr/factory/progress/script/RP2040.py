#!/usr/bin/python
import serial
import time
import subprocess
import json
import tempfile
import shutil
import os


source_file = "hello_serial.uf2"
mount_path = "/tmp/serial_mount_point"


res = subprocess.run(['lsblk', '-OJ'], stdout=subprocess.PIPE)
p = ""

for i in json.loads(res.stdout)['blockdevices']:
    if 'RPI' in (i.get('vendor') or ""):
        p = i['path']
if not p:
    print("正在进入刷入模式...", flush=True)
    subprocess.run('gpioset gpiochip1 60=1', shell=True, check=True)
    subprocess.run('gpioset gpiochip1 61=1', shell=True, check=True)
    time.sleep(0.5)
    subprocess.run('gpioset gpiochip1 60=0', shell=True, check=True)
    subprocess.run('gpioset gpiochip1 61=0', shell=True, check=True)
    time.sleep(2)
    res = subprocess.run(['lsblk', '-OJ'], stdout=subprocess.PIPE)
    for i in json.loads(res.stdout)['blockdevices']:
        if 'RPI' in (i.get('vendor') or ""):
            p = i['path']
    if not p:
        print("进入失败...")
        exit(1)

p += '1'

os.makedirs(mount_path, exist_ok=True)
try:
    res = subprocess.run(['mount', p, mount_path],check=True)
except subprocess.CalledProcessError as e:
    print("无法挂载", flush=True)
    exit(2)
print("复制文件中...", flush=True)
shutil.copy(source_file, mount_path)
try:
    subprocess.run(['umount', mount_path], check=True)
except subprocess.CalledProcessError:
    print("无法卸载", flush=True)
    time.sleep(2)

ser = serial.Serial('/dev/ttyS0', 115200, timeout=1)


time.sleep(2)

try:
    for i in range(10):
        if ser.in_waiting > 0:
            data = ser.readline().decode('utf-8').rstrip()
            if data == "Hello, world!":
                print("success", flush=True)
                exit(0)
        print("等待", i, flush=True)
        time.sleep(1)
except Exception as e:
    print("error", flush=True)
    print(e)
print("失败")
exit(1)