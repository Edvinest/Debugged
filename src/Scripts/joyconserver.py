#!/usr/bin/env python3
import math, time, socket, threading
from evdev import list_devices, InputDevice, ecodes

UDP_IP = "127.0.0.1"
UDP_PORT = 4243

sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)

# -------------------------------
# Find all IMU devices (Joy-Cons)
# -------------------------------
def find_imu_devices():
    devices = []
    for fn in list_devices():
        d = InputDevice(fn)
        if "Joy-Con" in d.name and "(IMU)" in d.name:
            if "(L)" in d.name:
                devices.append(("L", d))
            elif "(R)" in d.name:
                devices.append(("R", d))
    if not devices:
        raise SystemExit("No Joy-Con IMU devices found (check permissions).")
    return devices

# axis mapping
axis_map = {
    ecodes.ABS_X: 'accel_x', ecodes.ABS_Y: 'accel_y', ecodes.ABS_Z: 'accel_z',
    ecodes.ABS_RX: 'gyro_x', ecodes.ABS_RY: 'gyro_y', ecodes.ABS_RZ: 'gyro_z'
}

# -------------------------------
# Worker for each Joy-Con
# -------------------------------
def handle_device(dev, tag):
    vals = {}
    roll = pitch = yaw = 0.0
    last_t = time.time()
    alpha = 0.98  # complementary filter weight
    last_send = 0.0
    send_interval = 1.0 / 60.0


    def gyro_to_rads(code, raw_value):
        info = dev.absinfo(code)
        if getattr(info, 'resolution', 0):
            return raw_value / info.resolution
        return math.radians(raw_value)

    for ev in dev.read_loop():
        if ev.type == ecodes.EV_ABS and ev.code in axis_map:
            vals[axis_map[ev.code]] = ev.value

            if all(k in vals for k in ('accel_x', 'accel_y', 'accel_z')):
                ax, ay, az = vals['accel_x'], vals['accel_y'], vals['accel_z']

                ai_x, ai_y, ai_z = dev.absinfo(ecodes.ABS_X), dev.absinfo(ecodes.ABS_Y), dev.absinfo(ecodes.ABS_Z)
                axn = (ax - ai_x.min)/(ai_x.max - ai_x.min)*2.0 - 1.0 if ai_x.max!=ai_x.min else ax
                ayn = (ay - ai_y.min)/(ai_y.max - ai_y.min)*2.0 - 1.0 if ai_y.max!=ai_y.min else ay
                azn = (az - ai_z.min)/(ai_z.max - ai_z.min)*2.0 - 1.0 if ai_z.max!=ai_z.min else az

                roll_acc = math.atan2(ayn, azn)
                pitch_acc = math.atan2(-axn, math.sqrt(ayn*ayn + azn*azn))

                now = time.time()
                dt = now - last_t
                last_t = now

                if all(k in vals for k in ('gyro_x', 'gyro_y', 'gyro_z')):
                    gx = gyro_to_rads(ecodes.ABS_RX, vals['gyro_x'])
                    gy = gyro_to_rads(ecodes.ABS_RY, vals['gyro_y'])
                    gz = gyro_to_rads(ecodes.ABS_RZ, vals['gyro_z'])

                    # Integrate gyroscope for orientation
                    roll  = alpha * (roll  + gx * dt) + (1 - alpha) * roll_acc
                    pitch = alpha * (pitch + gy * dt) + (1 - alpha) * pitch_acc
                    yaw  += gz * dt  # yaw only from gyro (will drift)
                else:
                    roll, pitch = roll_acc, pitch_acc

                # Normalize yaw to [-pi, pi]
                if yaw > math.pi:
                    yaw -= 2 * math.pi
                elif yaw < -math.pi:
                    yaw += 2 * math.pi

                if now - last_send >= send_interval:
                    msg = f"{tag}:{roll:.4f},{pitch:.4f},{yaw:.4f}"
                    sock.sendto(msg.encode(), (UDP_IP, UDP_PORT))
                    last_send = now

# -------------------------------
# Main
# -------------------------------
devices = find_imu_devices()
print("Using devices:")
for tag, dev in devices:
    print(f"  {tag}: {dev.path} {dev.name}")
    threading.Thread(target=handle_device, args=(dev, tag), daemon=True).start()

print("Streaming IMU data (yaw, pitch, roll) over UDP on", UDP_IP, UDP_PORT)

# Keep main thread alive
while True:
    time.sleep(1)
