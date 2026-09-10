#!/usr/bin/env python3
import os
import sys
import json
import socket
import subprocess

def get_special_name():
    try:
        out = subprocess.check_output(['hyprctl', 'monitors', '-j'], stderr=subprocess.DEVNULL)
        monitors = json.loads(out)
        target_mon = os.environ.get('WAYBAR_OUTPUT_NAME')
        for m in monitors:
            if target_mon and m.get('name') != target_mon:
                continue
            if not target_mon and not m.get('focused'):
                continue
            sp = m.get('specialWorkspace', {})
            name = sp.get('name', '')
            if name.startswith('special:'):
                return name[len('special:'):]
            return name
    except Exception:
        return ''
    return ''

ICONS = {
    'spotify': '',
    'satty': '󰹑',
}
DEFAULT_ICON = '󰘳'

def render_json(sp_name):
    if not sp_name:
        return json.dumps({"text": "", "alt": "", "class": "empty"})
    icon = ICONS.get(sp_name, DEFAULT_ICON)
    text = f"{icon} {sp_name}"
    tooltip = f"Workspace Especial: {sp_name}\nClique para fechar"
    return json.dumps({
        "text": text,
        "alt": sp_name,
        "tooltip": tooltip,
        "class": "active"
    })

def main():
    current_sp = get_special_name()
    print(render_json(current_sp), flush=True)

    runtime_dir = os.environ.get('XDG_RUNTIME_DIR', f"/run/user/{os.getuid()}")
    instance = os.environ.get('HYPRLAND_INSTANCE_SIGNATURE')
    if not instance:
        hypr_dir = os.path.join(runtime_dir, 'hypr')
        if os.path.isdir(hypr_dir):
            for entry in os.listdir(hypr_dir):
                if os.path.exists(os.path.join(hypr_dir, entry, '.socket2.sock')):
                    instance = entry
                    break

    if not instance:
        return

    sock_path = os.path.join(runtime_dir, 'hypr', instance, '.socket2.sock')

    while True:
        try:
            with socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) as s:
                s.connect(sock_path)
                buf = ""
                while True:
                    data = s.recv(1024).decode('utf-8', errors='replace')
                    if not data:
                        break
                    buf += data
                    while '\n' in buf:
                        line, buf = buf.split('\n', 1)
                        event = line.split('>>')[0]
                        if any(event.startswith(prefix) for prefix in (
                            'activespecial', 'focusedmon', 'destroyworkspace', 'workspace'
                        )):
                            new_sp = get_special_name()
                            if new_sp != current_sp:
                                current_sp = new_sp
                                print(render_json(current_sp), flush=True)
        except Exception:
            import time
            time.sleep(1)

if __name__ == '__main__':
    main()
