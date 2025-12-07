#!/usr/bin/env python3
import math, time, socket, threading
from evdev import list_devices, InputDevice, ecodes

# --- CONFIGURATION ---
UDP_IP = "127.0.0.1"
UDP_PORT = 4243
sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)

# --- SCALING (SEPARATED) ---
SCALE_GYRO = 100000.0  # Gyro needs massive damping
SCALE_ACCEL = 100.0    # Accel needs light damping

# --- THRESHOLDS ---
THRESH_SWING = 60.0    # Gyro Speed
THRESH_STAB = 70.0     # Accel Magnitude (Must beat the ~50.0 noise floor)

DEADZONE_GYRO = 5.0

# Safety: Can't stab while swinging
MAX_ROT_FOR_STAB = 15

# Cooldowns
COOLDOWN = 0.5

def get_motion_name(gx, gy):
    angle = math.atan2(gy, -gx)
    pi = math.pi
    if angle < -7*pi/8: return "left"
    if angle < -3*pi/8: return "down"
    if angle < pi/8:    return "right"
    if angle < 5*pi/8:  return "up"
    return "left"

def handle_device(dev, tag):
    c_gx, c_gy, c_gz = 0.0, 0.0, 0.0
    c_ax, c_ay, c_az = 0.0, 0.0, 0.0
    has_data = False

    output_mult = 10.0

    print(f"[{tag}] Calibrating... Keep FLAT!")
    calibrating = True
    calib_count = 0
    off_gx, off_gy, off_gz = 0.0, 0.0, 0.0
    off_ax, off_ay, off_az = 0.0, 0.0, 0.0

    last_trigger = 0

    for ev in dev.read_loop():
        if ev.type == ecodes.EV_ABS:
            if ev.code == ecodes.ABS_RX: c_gx = ev.value
            elif ev.code == ecodes.ABS_RY: c_gy = ev.value
            elif ev.code == ecodes.ABS_RZ: c_gz = ev.value
            elif ev.code == ecodes.ABS_X: c_ax = ev.value
            elif ev.code == ecodes.ABS_Y: c_ay = ev.value
            elif ev.code == ecodes.ABS_Z: c_az = ev.value
            else: continue
            has_data = True

        if has_data:
            # 1. SCALE (Using separate scales now)
            gx = c_gx / SCALE_GYRO
            gy = c_gy / SCALE_GYRO
            gz = c_gz / SCALE_GYRO

            ax = c_ax / SCALE_ACCEL
            ay = c_ay / SCALE_ACCEL
            az = c_az / SCALE_ACCEL

            # 2. CALIBRATION
            if calibrating:
                off_gx += gx; off_gy += gy; off_gz += gz
                off_ax += ax; off_ay += ay; off_az += az
                calib_count += 1
                if calib_count > 100:
                    off_gx /= 100; off_gy /= 100; off_gz /= 100
                    off_ax /= 100; off_ay /= 100; off_az /= 100
                    calibrating = False
                    print(f"[{tag}] Ready!")
                continue

            # Apply Offset
            gx -= off_gx; gy -= off_gy; gz -= off_gz
            ax -= off_ax; ay -= off_ay; az -= off_az

            # 3. MAPPING
            if tag == "R":
                final_gx = gx
                final_gy = -gy
                final_gz = -gz
            else:
                final_gx = gx
                final_gy = -gy
                final_gz = -gz

            # 4. DEADZONE
            if abs(final_gx) < DEADZONE_GYRO: final_gx = 0.0
            if abs(final_gy) < DEADZONE_GYRO: final_gy = 0.0
            if abs(final_gz) < DEADZONE_GYRO: final_gz = 0.0

            # 5. LOGIC
            rot_speed = math.sqrt(final_gx**2 + final_gy**2 + final_gz**2)
            accel_mag = math.sqrt(ax**2 + ay**2 + az**2)

            motion = "none"
            now = time.time()

            if now - last_trigger > COOLDOWN:

                # PRIORITY 1: SWING
                if rot_speed > THRESH_SWING:
                    motion = get_motion_name(final_gx, final_gy)
                    last_trigger = now
                    print(f"[{tag}] ACTION: {motion} (Spd: {rot_speed:.0f})")

                # PRIORITY 2: STAB
                # Condition: High Accel + Low Rotation
                elif accel_mag > THRESH_STAB and rot_speed < MAX_ROT_FOR_STAB:
                    motion = "stab"
                    last_trigger = now
                    # Added debug print to see the force value
                    print(f"[{tag}] ACTION: STAB !!! (Force: {accel_mag:.0f} | Rot: {rot_speed:.0f})")

            # 6. SEND
            norm_gx = final_gx / output_mult
            norm_gy = final_gy / output_mult
            norm_gz = final_gz / output_mult

            # Send raw accel / 100 for consistency in sway
            norm_ax = ax / 100.0
            norm_ay = ay / 100.0
            norm_az = az / 100.0

            msg = f"{tag}:{norm_gx:.4f},{norm_gy:.4f},{norm_gz:.4f},{norm_ax:.4f},{norm_ay:.4f},{norm_az:.4f},{motion}"
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

    print("--- JOY-CON SERVER RUNNING ---")
    while True: time.sleep(1)
