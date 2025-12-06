#!/usr/bin/env python3
import math, time, socket, threading
from evdev import list_devices, InputDevice, ecodes

# --- CONFIGURATION ---
UDP_IP = "127.0.0.1"
UDP_PORT = 4243
sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)

# --- SCALING & TUNING ---
# We treat Right JoyCon as "Raw Integers" (Huge Numbers)
SCALE_R = 100000.0  # Divides "3,000,000" down to "30.0"
THRESH_R = 35.0     # Speed required to trigger
DEADZONE_R = 5.0    # Ignore noise

# Left JoyCon (Standard)
SCALE_L = 1.0
THRESH_L = 3.5
DEADZONE_L = 0.15

COOLDOWN = 0.25

def get_motion_name(gx, gy):
    angle = math.atan2(gy, -gx)
    pi = math.pi
    if angle < -7*pi/8: return "left"
    #if angle < -5*pi/8: return "diag_down_left"
    if angle < -3*pi/8: return "down"
    #if angle < -pi/8:   return "diag_down_right"
    if angle < pi/8:    return "right"
    #if angle < 3*pi/8:  return "diag_up_right"
    if angle < 5*pi/8:  return "up"
   # if angle < 7*pi/8:  return "diag_up_left"
    return "left"

def handle_device(dev, tag):
    current_gx = 0.0
    current_gy = 0.0
    current_gz = 0.0
    has_data = False

    # Logic Selection
    if tag == "L":
        divisor = SCALE_L
        thresh = THRESH_L
        dzone = DEADZONE_L
        output_mult = 1.0
    else:
        divisor = SCALE_R
        thresh = THRESH_R
        dzone = DEADZONE_R
        output_mult = 10.0 # Boost Right JC slightly for Godot visual feel

    # Calibration
    print(f"[{tag}] Calibrating... Keep FLAT!")
    calibrating = True
    calib_count = 0
    off_gx, off_gy, off_gz = 0.0, 0.0, 0.0

    last_trigger = 0

    for ev in dev.read_loop():
        if ev.type == ecodes.EV_ABS:
            if ev.code == ecodes.ABS_RX: current_gx = ev.value
            elif ev.code == ecodes.ABS_RY: current_gy = ev.value
            elif ev.code == ecodes.ABS_RZ: current_gz = ev.value
            else: continue
            has_data = True

        if has_data:
            # 1. READ & SCALE
            gx = current_gx / divisor
            gy = current_gy / divisor
            gz = current_gz / divisor

            # 2. CALIBRATION
            if calibrating:
                off_gx += gx
                off_gy += gy
                off_gz += gz
                calib_count += 1
                if calib_count > 100:
                    off_gx /= 100
                    off_gy /= 100
                    off_gz /= 100
                    calibrating = False
                    print(f"[{tag}] Ready! Offsets: {off_gx:.1f}, {off_gy:.1f}")
                continue

            # Apply Offset
            gx -= off_gx
            gy -= off_gy
            gz -= off_gz

            # 3. MAPPING FIX (Un-swapped based on your logs)
            if tag == "R":
                # Your log showed:
                # UP affected X (incorrectly swapped to X) -> Should be Y
                # LEFT affected Y (incorrectly swapped to Y) -> Should be X

                # So we simply DON'T swap.
                # But we do need to invert Y based on standard screen coords
                final_gx = gx
                final_gy = -gy
                final_gz = -gz
            else:
                final_gx = gx
                final_gy = gy
                final_gz = gz

            # 4. DEADZONE
            if abs(final_gx) < dzone: final_gx = 0.0
            if abs(final_gy) < dzone: final_gy = 0.0
            if abs(final_gz) < dzone: final_gz = 0.0

            # 5. LOGIC
            speed = math.sqrt(final_gx**2 + final_gy**2 + final_gz**2)
            motion = "none"

            now = time.time()
            if now - last_trigger > COOLDOWN:
                if speed > thresh:
                    motion = get_motion_name(final_gx, final_gy)
                    last_trigger = now
                    print(f"[{tag}] ACTION: {motion} ({speed:.0f})")

            # 6. SEND TO GODOT
            # We divide by 10.0 just to normalize the "Speed" visual for Godot
            # (Godot expects ~1.0 to 10.0 rad/s, we have ~30.0)
            norm_gx = final_gx / output_mult
            norm_gy = final_gy / output_mult
            norm_gz = final_gz / output_mult

            msg = f"{tag}:{norm_gx:.4f},{norm_gy:.4f},{norm_gz:.4f},0,0,0,{motion}"
            sock.sendto(msg.encode(), (UDP_IP, UDP_PORT))

def find_devices():
    devs = []
    print("Scanning...")
    for fn in list_devices():
        d = InputDevice(fn)
        if "Joy-Con" in d.name and "(IMU)" in d.name:
            if "Combined" in d.name: continue
            tag = "L" if "(L)" in d.name else "R"
            devs.append((tag, d))
    return devs

devs = find_devices()
if not devs:
    print("No Joy-Cons found.")
else:
    for tag, d in devs:
        t = threading.Thread(target=handle_device, args=(d, tag))
        t.daemon = True
        t.start()

    print("--- FINAL V2 TRACKER RUNNING ---")
    while True: time.sleep(1)
