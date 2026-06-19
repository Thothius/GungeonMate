import http.server
import socketserver
import subprocess
import json
import urllib.parse
import os
import sys
from datetime import datetime

PORT = 4040
TASKS_FILE = 'tool/devops_tasks.json'
BUGS_FILE = 'tool/devops_bugs.json'

# Global databases loaded once at startup
GUNS_DB = []
ITEMS_DB = []

try:
    if os.path.exists('assets/data/guns.json'):
        with open('assets/data/guns.json', 'r', encoding='utf-8') as f:
            GUNS_DB = json.load(f)
            for g in GUNS_DB:
                g['is_gun'] = True
except Exception as e:
    print(f"Warning: Failed to load guns.json: {e}")

try:
    if os.path.exists('assets/data/items.json'):
        with open('assets/data/items.json', 'r', encoding='utf-8') as f:
            ITEMS_DB = json.load(f)
            for i in ITEMS_DB:
                i['is_gun'] = False
except Exception as e:
    print(f"Warning: Failed to load items.json: {e}")

def get_current_version():
    try:
        if not os.path.exists('pubspec.yaml'):
            return 'Unknown (no pubspec.yaml)'
        with open('pubspec.yaml', 'r', encoding='utf-8') as f:
            for line in f:
                if line.strip().startswith('version:'):
                    return line.replace('version:', '').strip()
    except Exception as e:
        return f'Unknown: {str(e)}'
    return 'Unknown'

def bump_version(minor=False):
    try:
        if not os.path.exists('pubspec.yaml'):
            return 'Error'
        with open('pubspec.yaml', 'r', encoding='utf-8') as f:
            lines = f.readlines()
            
        line_idx = -1
        current_full_line = ''
        for i, line in enumerate(lines):
            if line.strip().startswith('version:'):
                current_full_line = line
                line_idx = i
                break
                
        if line_idx == -1:
            return 'Error'
            
        version_value = current_full_line.split('version:')[1].strip()
        parts = version_value.split('+')
        version_str = parts[0]
        build_str = parts[1] if len(parts) > 1 else '1'
        
        version_num_parts = version_str.split('.')
        major = int(version_num_parts[0]) if version_num_parts[0].isdigit() else 0
        minor_num = int(version_num_parts[1]) if len(version_num_parts) > 1 and version_num_parts[1].isdigit() else 0
        patch = int(version_num_parts[2]) if len(version_num_parts) > 2 and version_num_parts[2].isdigit() else 0
        
        build_num = int(build_str) if build_str.isdigit() else 1
        build_num += 1
        
        if minor:
            minor_num += 1
            patch = 0
        else:
            patch += 1
            
        new_version_value = f"{major}.{minor_num}.{patch}+{build_num}"
        lines[line_idx] = f"version: {new_version_value}\n"
        
        with open('pubspec.yaml', 'w', encoding='utf-8') as f:
            f.writelines(lines)
            
        return new_version_value
    except Exception as e:
        return f"Error: {str(e)}"

def get_changelog():
    try:
        if os.path.exists('assets/data/changelog.json'):
            with open('assets/data/changelog.json', 'r', encoding='utf-8') as f:
                return json.load(f)
    except Exception:
        pass
    return []

def add_changelog_release(release):
    try:
        log = get_changelog()
        if 'date' not in release or not release['date'].strip():
            release['date'] = datetime.now().strftime("%B %d, %Y")
        
        # Prepend to make newest release show first
        log.insert(0, release)
        
        with open('assets/data/changelog.json', 'w', encoding='utf-8') as f:
            json.dump(log, f, indent=2)
        return True
    except Exception as e:
        print(f"Error adding changelog: {e}")
        return False

def get_tasks():
    try:
        if not os.path.exists(TASKS_FILE):
            default_tasks = [
                {"id": 1, "text": "Conduct UX/UI accessibility & contrast checks", "done": True, "priority": "high"},
                {"id": 2, "text": "Meticulously wrap secondary views in GoopText", "done": True, "priority": "high"},
                {"id": 3, "text": "Setup local Python-based DevOps automation panel", "done": True, "priority": "medium"},
                {"id": 4, "text": "Run a clean production compile of the Release APK (0.9.5)", "done": False, "priority": "high"},
                {"id": 5, "text": "Publish updated codebase branches to GitHub master & dev", "done": False, "priority": "medium"},
                {"id": 6, "text": "Prepare Google Play Store developer launch metadata", "done": False, "priority": "low"}
            ]
            os.makedirs(os.path.dirname(TASKS_FILE), exist_ok=True)
            with open(TASKS_FILE, 'w', encoding='utf-8') as f:
                json.dump(default_tasks, f, indent=2)
            return default_tasks
        with open(TASKS_FILE, 'r', encoding='utf-8') as f:
            return json.load(f)
    except Exception as e:
        print(f"Error reading tasks: {e}")
        return []

def save_tasks(tasks):
    try:
        os.makedirs(os.path.dirname(TASKS_FILE), exist_ok=True)
        with open(TASKS_FILE, 'w', encoding='utf-8') as f:
            json.dump(tasks, f, indent=2)
        return True
    except Exception as e:
        print(f"Error saving tasks: {e}")
        return False

def get_bugs():
    try:
        if not os.path.exists(BUGS_FILE):
            return []
        with open(BUGS_FILE, 'r', encoding='utf-8') as f:
            return json.load(f)
    except Exception:
        pass
    return []

def save_bugs(bugs):
    try:
        os.makedirs(os.path.dirname(BUGS_FILE), exist_ok=True)
        with open(BUGS_FILE, 'w', encoding='utf-8') as f:
            json.dump(bugs, f, indent=2)
        return True
    except Exception:
        return False

def add_bug_report(bug):
    try:
        bugs = get_bugs()
        bug['id'] = int(datetime.now().timestamp() * 1000)
        bug['timestamp'] = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        bugs.insert(0, bug)
        save_bugs(bugs)
        return True
    except Exception as e:
        print(f"Error adding bug: {e}")
        return False

def run_command_stream(cmd, msg, wfile):
    commands = []
    if cmd == 'git_commit':
        if not msg.strip():
            wfile.write(b"data: stderr: [ERROR] Commit message is required!\n\n")
            wfile.flush()
            return
        commands = [
            ['git', 'add', '.'],
            ['git', 'commit', '-m', msg]
        ]
    elif cmd == 'git_push_dev':
        commands = [['git', 'push', 'origin', 'dev']]
    elif cmd == 'git_push_master':
        commands = [['git', 'push', 'origin', 'master']]
    elif cmd == 'build_apk':
        commands = [['flutter', 'build', 'apk', '--release']]
    elif cmd == 'build_appbundle':
        commands = [['flutter', 'build', 'appbundle', '--release']]
    elif cmd == 'flutter_clean':
        commands = [['flutter', 'clean']]
    else:
        wfile.write(f"data: stderr: [ERROR] Unknown command: {cmd}\n\n".encode('utf-8'))
        wfile.flush()
        return

    for full_cmd in commands:
        wfile.write(f"data: stdout: [CMD] Running: {' '.join(full_cmd)}\n\n".encode('utf-8'))
        wfile.flush()
        
        try:
            process = subprocess.Popen(
                full_cmd,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                shell=True if os.name == 'nt' else False,
                text=True,
                bufsize=1,
                universal_newlines=True
            )
            
            while True:
                line = process.stdout.readline()
                if not line and process.poll() is not None:
                    break
                if line:
                    clean_line = line.strip().replace('\r', '')
                    wfile.write(f"data: stdout: {clean_line}\n\n".encode('utf-8'))
                    wfile.flush()
            
            stderr_output = process.stderr.read()
            if stderr_output:
                for line in stderr_output.split('\n'):
                    if line.strip():
                        clean_line = line.strip().replace('\r', '')
                        wfile.write(f"data: stderr: {clean_line}\n\n".encode('utf-8'))
                        wfile.flush()
                        
            exit_code = process.wait()
            wfile.write(f"data: stdout: [EXIT] Command completed with code {exit_code}\n\n".encode('utf-8'))
            wfile.flush()
            if exit_code != 0:
                break
        except Exception as e:
            wfile.write(f"data: stderr: [ERROR] Process failed to execute: {str(e)}\n\n".encode('utf-8'))
            wfile.flush()
            break

class DevOpsHandler(http.server.BaseHTTPRequestHandler):
    def log_message(self, format, *args):
        return

    def end_headers(self):
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Access-Control-Allow-Methods', 'GET, POST, OPTIONS')
        self.send_header('Access-Control-Allow-Headers', 'Content-Type')
        super().end_headers()

    def do_OPTIONS(self):
        self.send_response(200)
        self.end_headers()

    def do_GET(self):
        parsed_url = urllib.parse.urlparse(self.path)
        path = parsed_url.path
        
        if path == '/':
            self.send_response(200)
            self.send_header('Content-Type', 'text/html')
            self.end_headers()
            self.wfile.write(get_html_content().encode('utf-8'))
        elif path == '/api/version':
            self.send_response(200)
            self.send_header('Content-Type', 'application/json')
            self.end_headers()
            ver = get_current_version()
            self.wfile.write(json.dumps({'version': ver}).encode('utf-8'))
        elif path == '/api/bump-patch':
            self.send_response(200)
            self.send_header('Content-Type', 'application/json')
            self.end_headers()
            ver = bump_version(minor=False)
            self.wfile.write(json.dumps({'version': ver}).encode('utf-8'))
        elif path == '/api/bump-minor':
            self.send_response(200)
            self.send_header('Content-Type', 'application/json')
            self.end_headers()
            ver = bump_version(minor=True)
            self.wfile.write(json.dumps({'version': ver}).encode('utf-8'))
        elif path == '/api/changelog':
            self.send_response(200)
            self.send_header('Content-Type', 'application/json')
            self.end_headers()
            self.wfile.write(json.dumps(get_changelog()).encode('utf-8'))
        elif path == '/api/tasks':
            self.send_response(200)
            self.send_header('Content-Type', 'application/json')
            self.end_headers()
            self.wfile.write(json.dumps(get_tasks()).encode('utf-8'))
        elif path == '/api/bugs':
            self.send_response(200)
            self.send_header('Content-Type', 'application/json')
            self.end_headers()
            self.wfile.write(json.dumps(get_bugs()).encode('utf-8'))
        elif path == '/api/database':
            self.send_response(200)
            self.send_header('Content-Type', 'application/json')
            self.end_headers()
            combined = GUNS_DB + ITEMS_DB
            self.wfile.write(json.dumps(combined).encode('utf-8'))
        elif path == '/api/run':
            query = urllib.parse.parse_qs(parsed_url.query)
            cmd = query.get('cmd', [''])[0]
            msg = query.get('msg', [''])[0]
            
            self.send_response(200)
            self.send_header('Content-Type', 'text/event-stream')
            self.send_header('Cache-Control', 'no-cache')
            self.send_header('Connection', 'keep-alive')
            self.end_headers()
            
            run_command_stream(cmd, msg, self.wfile)
            self.wfile.write(b"data: [DONE]\n\n")
        else:
            self.send_response(404)
            self.end_headers()

    def do_POST(self):
        parsed_url = urllib.parse.urlparse(self.path)
        path = parsed_url.path
        
        content_length = int(self.headers.get('Content-Length', 0))
        post_data = self.rfile.read(content_length).decode('utf-8') if content_length > 0 else '{}'
        
        try:
            body = json.loads(post_data)
        except Exception:
            body = {}
            
        if path == '/api/changelog':
            self.send_response(200)
            self.send_header('Content-Type', 'application/json')
            self.end_headers()
            success = add_changelog_release(body)
            self.wfile.write(json.dumps({'success': success, 'changelog': get_changelog()}).encode('utf-8'))
        elif path == '/api/tasks':
            self.send_response(200)
            self.send_header('Content-Type', 'application/json')
            self.end_headers()
            success = save_tasks(body.get('tasks', []))
            self.wfile.write(json.dumps({'success': success, 'tasks': get_tasks()}).encode('utf-8'))
        elif path == '/api/bugs':
            self.send_response(200)
            self.send_header('Content-Type', 'application/json')
            self.end_headers()
            success = add_bug_report(body)
            self.wfile.write(json.dumps({'success': success, 'bugs': get_bugs()}).encode('utf-8'))
        elif path == '/api/bugs/clear':
            self.send_response(200)
            self.send_header('Content-Type', 'application/json')
            self.end_headers()
            success = save_bugs([])
            self.wfile.write(json.dumps({'success': success, 'bugs': []}).encode('utf-8'))
        else:
            self.send_response(404)
            self.end_headers()

def get_html_content():
    return r'''<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>GungeonMate Control Center</title>
  <script src="https://cdn.tailwindcss.com"></script>
  <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
  <style>
    @import url('https://fonts.googleapis.com/css2?family=Montserrat:wght@400;700;900&family=Share+Tech+Mono&display=swap');
    body {
      font-family: 'Montserrat', sans-serif;
      background: radial-gradient(circle, #251216 0%, #0d0608 100%);
      color: #eceff1;
    }
    .console-font {
      font-family: 'Share Tech Mono', monospace;
    }
    .retro-glow {
      box-shadow: 0 0 25px rgba(198, 40, 40, 0.25);
    }
    .retro-border {
      border: 1.5px solid #c62828;
    }
    .glow-gold {
      color: #ffd54f;
      text-shadow: 0 0 10px rgba(255, 213, 79, 0.5);
    }
    .glow-green {
      color: #a7ffd5;
      text-shadow: 0 0 10px rgba(167, 255, 213, 0.5);
    }
    
    /* STUNNING CRT SCREEN EFFECTS */
    @keyframes crt-flicker {
      0% { opacity: 0.985; }
      50% { opacity: 0.995; }
      100% { opacity: 0.985; }
    }
    .crt-screen {
      animation: crt-flicker 0.2s infinite;
      position: relative;
    }
    /* Phosphor lines */
    .crt-screen::before {
      content: " ";
      display: block;
      position: absolute;
      top: 0; left: 0; bottom: 0; right: 0;
      background: linear-gradient(rgba(18, 16, 16, 0) 50%, rgba(0, 0, 0, 0.22) 50%), linear-gradient(90deg, rgba(255, 0, 0, 0.04), rgba(0, 255, 0, 0.01), rgba(0, 0, 255, 0.04));
      z-index: 10;
      background-size: 100% 4px, 6px 100%;
      pointer-events: none;
    }
    /* Scanning beam */
    @keyframes scanline-anim {
      0% { top: -100%; }
      100% { top: 100%; }
    }
    .crt-screen::after {
      content: " ";
      display: block;
      position: absolute;
      left: 0; right: 0; height: 35px;
      background: linear-gradient(to bottom, rgba(167, 255, 213, 0) 0%, rgba(167, 255, 213, 0.08) 50%, rgba(167, 255, 213, 0) 100%);
      z-index: 11;
      animation: scanline-anim 8s linear infinite;
      pointer-events: none;
    }

    .custom-scrollbar::-webkit-scrollbar {
      width: 6px;
    }
    .custom-scrollbar::-webkit-scrollbar-track {
      background: rgba(0, 0, 0, 0.2);
    }
    .custom-scrollbar::-webkit-scrollbar-thumb {
      background: rgba(198, 40, 40, 0.4);
      border-radius: 3px;
    }
    .custom-scrollbar::-webkit-scrollbar-thumb:hover {
      background: rgba(198, 40, 40, 0.7);
    }
  </style>
</head>
<body class="min-h-screen p-4 md:p-8 flex flex-col justify-between">

  <!-- Floating Console Control Drawer overlay -->
  <div id="drawer-backdrop" onclick="toggleDrawer(false)" class="fixed inset-0 bg-black/70 z-40 hidden transition-opacity duration-300"></div>
  <div id="control-drawer" class="fixed inset-y-0 right-0 w-80 md:w-96 bg-[#120d16] border-l-2 border-red-900 z-50 transform translate-x-full transition-transform duration-300 ease-in-out p-6 shadow-2xl flex flex-col justify-between overflow-y-auto custom-scrollbar">
    <div>
      <div class="flex justify-between items-center border-b border-red-900/40 pb-4 mb-6">
        <h3 class="text-sm font-black text-[#ffd54f] tracking-widest uppercase flex items-center gap-2">
          <i class="fa-solid fa-gears text-red-500 animate-spin"></i> Console Bridge Commands
        </h3>
        <button onclick="toggleDrawer(false)" class="text-gray-500 hover:text-white transition text-lg"><i class="fa-solid fa-xmark"></i></button>
      </div>

      <!-- Git Operations -->
      <div class="bg-[#1f1925] border border-red-950 rounded-xl p-4 shadow-inner mb-6">
        <h4 class="text-xs font-black text-red-500 uppercase tracking-wider mb-3 flex items-center gap-1.5">
          <i class="fa-brands fa-git-alt text-[#ffd54f]"></i> Git Controls
        </h4>
        <div class="flex flex-col gap-3">
          <div>
            <label class="block text-[9px] uppercase tracking-wider text-gray-500 font-black mb-1">Commit Message</label>
            <input type="text" id="commit-msg" placeholder="e.g. Fixed template string rendering..." 
                   class="w-full bg-[#110d16] border border-red-900/40 rounded-lg py-1.5 px-3 text-xs focus:outline-none focus:border-red-600 text-white placeholder-gray-600">
          </div>
          
          <button onclick="triggerCommand('git_commit')" 
                  class="w-full bg-[#c62828] hover:bg-red-700 active:bg-red-800 text-white font-bold py-2 px-3 rounded-lg text-xs tracking-wider uppercase transition duration-150 shadow-md">
            <i class="fa-solid fa-code-commit mr-1.5"></i> Commit Changes
          </button>
          
          <div class="grid grid-cols-2 gap-2 mt-1">
            <button onclick="triggerCommand('git_push_dev')" 
                    class="bg-blue-600 hover:bg-blue-700 active:bg-blue-800 text-white font-bold py-2 px-2 rounded-lg text-[10px] tracking-wider uppercase transition duration-150 shadow-md">
              <i class="fa-solid fa-cloud-arrow-up mr-1"></i> Push Dev
            </button>
            <button onclick="triggerCommand('git_push_master')" 
                    class="bg-amber-600 hover:bg-amber-700 active:bg-amber-800 text-white font-bold py-2 px-2 rounded-lg text-[10px] tracking-wider uppercase transition duration-150 shadow-md">
              <i class="fa-solid fa-trophy mr-1"></i> Push Master
            </button>
          </div>
        </div>
      </div>

      <!-- Compilation Builds -->
      <div class="bg-[#1f1925] border border-red-950 rounded-xl p-4 shadow-inner mb-6">
        <h4 class="text-xs font-black text-red-500 uppercase tracking-wider mb-3 flex items-center gap-1.5">
          <i class="fa-solid fa-cubes text-[#ffd54f]"></i> Project Builds
        </h4>
        <div class="flex flex-col gap-2.5">
          <button onclick="triggerCommand('build_apk')" 
                  class="w-full bg-[#00b0ff] hover:bg-cyan-600 active:bg-cyan-700 text-black font-black py-2 px-3 rounded-lg text-xs tracking-widest uppercase transition duration-150 shadow-md">
            <i class="fa-solid fa-android mr-1.5 text-sm"></i> Build Release APK
          </button>
          <button onclick="triggerCommand('build_appbundle')" 
                  class="w-full bg-[#00e676] hover:bg-green-600 active:bg-green-700 text-black font-black py-2 px-3 rounded-lg text-xs tracking-widest uppercase transition duration-150 shadow-md">
            <i class="fa-solid fa-box-archive mr-1.5 text-sm"></i> Build AppBundle (AAB)
          </button>
          <button onclick="triggerCommand('flutter_clean')" 
                  class="w-full bg-gray-800 hover:bg-gray-700 active:bg-gray-600 text-white font-bold py-1.5 px-3 rounded-lg text-xs tracking-wider uppercase transition duration-150 border border-gray-700">
            <i class="fa-solid fa-eraser mr-1.5"></i> Clean Cache
          </button>
        </div>
      </div>

      <!-- Live Versioning -->
      <div class="bg-[#1f1925] border border-red-950 rounded-xl p-4 shadow-inner">
        <h4 class="text-xs font-black text-red-500 uppercase tracking-wider mb-3 flex items-center gap-1.5">
          <i class="fa-solid fa-clock-rotate-left text-[#ffd54f]"></i> Live Versioning
        </h4>
        <div class="grid grid-cols-2 gap-2">
          <button onclick="bumpVersion('patch')" 
                  class="bg-[#110d16] hover:bg-gray-900 border border-red-900/40 hover:border-red-600 text-[#ffd54f] font-bold py-2 px-2 rounded-lg text-[10px] tracking-wider uppercase transition duration-150 flex flex-col items-center justify-center gap-1 shadow-md">
            <i class="fa-solid fa-arrow-up-right-dots text-sm"></i>
            <span>Bump Patch</span>
          </button>
          <button onclick="bumpVersion('minor')" 
                  class="bg-[#110d16] hover:bg-gray-900 border border-red-900/40 hover:border-red-600 text-[#ffd54f] font-bold py-2 px-2 rounded-lg text-[10px] tracking-wider uppercase transition duration-150 flex flex-col items-center justify-center gap-1 shadow-md">
            <i class="fa-solid fa-circle-up text-sm"></i>
            <span>Bump Minor</span>
          </button>
        </div>
      </div>
    </div>
    
    <div class="text-[9px] text-gray-600 font-bold text-center tracking-widest mt-6">
      GUNGEONMATE CONSOLE PANEL v1.0.2
    </div>
  </div>

  <!-- Main Container -->
  <div class="max-w-6xl w-full mx-auto bg-[#18131d]/95 rounded-2xl retro-border p-6 md:p-8 shadow-2xl retro-glow backdrop-blur-md">
    
    <!-- Title Header -->
    <div class="flex flex-col md:flex-row justify-between items-center border-b border-red-900/40 pb-6 mb-6">
      <div class="text-center md:text-left flex items-center gap-4">
        <div class="relative w-14 h-14 bg-black rounded-full border border-yellow-500/50 flex items-center justify-center overflow-hidden">
          <img src="https://raw.githubusercontent.com/Thothius/GungeonMate/master/gungeon_mate/assets/animations/Goopton_idle.gif" 
               class="w-12 h-12 object-contain" 
               onerror="this.src='https://raw.githubusercontent.com/Thothius/GungeonMate/master/gungeon_mate/assets/animations/Tailor_idle.gif'">
        </div>
        <div>
          <h1 class="text-3xl md:text-4xl font-black tracking-widest text-[#ffd54f] glow-gold flex items-center justify-center md:justify-start gap-2">
            GUNGEON MATE CONTROL
          </h1>
          <p class="text-[10px] tracking-widest text-red-500/80 font-black uppercase mt-0.5 font-mono">DEV CENTER // DIAGNOSTICS & DEVOPS</p>
        </div>
      </div>
      <div class="mt-4 md:mt-0 flex items-center gap-3">
        <span class="px-3 py-1 bg-green-500/10 border border-green-500/30 text-green-400 text-xs rounded-full flex items-center gap-1.5 font-bold">
          <span class="w-2 h-2 bg-green-500 rounded-full animate-ping"></span> ONLINE
        </span>
        <span id="version-badge" class="px-3 py-1 bg-red-500/10 border border-red-500/30 text-red-400 text-xs rounded-full font-bold">
          v0.0.0
        </span>
      </div>
    </div>

    <!-- Tab Selectors -->
    <div class="flex flex-wrap border-b border-red-950/50 mb-6 gap-1 md:gap-2">
      <button onclick="switchTab('bridge')" id="tab-btn-bridge" class="px-4 md:px-5 py-2.5 text-xs tracking-widest font-black uppercase border-b-2 border-red-600 text-white transition-all flex items-center gap-2">
        <i class="fa-solid fa-terminal text-red-500"></i> Dev Bridge
      </button>
      <button onclick="switchTab('changelog')" id="tab-btn-changelog" class="px-4 md:px-5 py-2.5 text-xs tracking-widest font-black uppercase border-b-2 border-transparent text-gray-500 hover:text-white transition-all flex items-center gap-2">
        <i class="fa-solid fa-receipt text-[#ffd54f]"></i> Changelog Editor
      </button>
      <button onclick="switchTab('database')" id="tab-btn-database" class="px-4 md:px-5 py-2.5 text-xs tracking-widest font-black uppercase border-b-2 border-transparent text-gray-500 hover:text-white transition-all flex items-center gap-2">
        <i class="fa-solid fa-book-journal-whills text-[#00e5ff]"></i> Wiki Database
      </button>
      <button onclick="switchTab('tasks')" id="tab-btn-tasks" class="px-4 md:px-5 py-2.5 text-xs tracking-widest font-black uppercase border-b-2 border-transparent text-gray-500 hover:text-white transition-all flex items-center gap-2">
        <i class="fa-solid fa-list-check text-green-400"></i> Roadmap
      </button>
      <button onclick="switchTab('bugs')" id="tab-btn-bugs" class="px-4 md:px-5 py-2.5 text-xs tracking-widest font-black uppercase border-b-2 border-transparent text-gray-500 hover:text-white transition-all flex items-center gap-2 relative">
        <i class="fa-solid fa-bug text-red-400 animate-pulse"></i> Bugs
        <span id="bug-tab-counter" class="absolute -top-1 -right-1.5 px-1.5 py-0.5 bg-red-600 text-[8px] text-white font-bold rounded-full hidden">
          0
        </span>
      </button>
    </div>

    <!-- TAB 1: COMMAND BRIDGE (STUNNING FULL-SCREEN RETRO TERMINAL) -->
    <div id="tab-content-bridge" class="tab-pane">
      <div class="relative w-full h-[550px] bg-[#07050a] rounded-xl retro-border overflow-hidden flex flex-col crt-screen shadow-inner">
        
        <!-- Terminal Header Bar with floating Open Controls Drawer button -->
        <div class="bg-[#150f1b] px-4 py-3 flex justify-between items-center border-b border-red-950 z-20">
          <span class="text-[10px] font-black tracking-widest text-red-500 flex items-center gap-2 font-mono">
            <span class="w-1.5 h-1.5 bg-red-600 rounded-full animate-ping"></span> RETRO TERM v1.0.2 // ACTIVE_PHOSPHOR_LOOP
          </span>
          <div class="flex items-center gap-3">
            <button onclick="toggleDrawer(true)" class="bg-[#c62828] hover:bg-red-700 border border-red-500/50 hover:border-red-400 text-white font-black px-3.5 py-1 rounded-lg text-[10px] tracking-wider uppercase transition-all flex items-center gap-1.5 shadow-md">
              <i class="fa-solid fa-screwdriver-wrench animate-pulse"></i> Commands Menu
            </button>
            <button onclick="clearConsole()" class="text-[10px] bg-gray-950/60 hover:bg-gray-900 border border-gray-800 text-gray-400 hover:text-white font-bold px-3 py-1 rounded-lg transition">
              CLEAR
            </button>
          </div>
        </div>

        <!-- Terminal Output - Full screen glowing layout -->
        <div id="console-output" class="console-font flex-1 p-6 overflow-y-auto text-xs space-y-2 text-[#a7ffd5] glow-green leading-relaxed max-h-[490px] relative z-20 custom-scrollbar">
          <div class="text-[#ffd54f]/50 font-mono">===================================================</div>
          <div class="text-[#ffd54f] font-mono">⚡ GungeonMate High-Phosphor console initialized. Active.</div>
          <div class="text-[#ffd54f]/50 font-mono">===================================================</div>
        </div>
        
      </div>
    </div>

    <!-- TAB 2: CHANGELOG EDITOR -->
    <div id="tab-content-changelog" class="tab-pane hidden">
      <div class="grid grid-cols-1 lg:grid-cols-12 gap-8">
        
        <!-- Add New Release Notes -->
        <div class="lg:col-span-5 bg-[#1f1925] border border-red-950 rounded-xl p-5 shadow-inner">
          <h2 class="text-sm font-black text-red-500 uppercase tracking-wider mb-4 flex items-center gap-2">
            <i class="fa-solid fa-plus-circle text-[#ffd54f]"></i> Create Release Note
          </h2>
          <div class="flex flex-col gap-4">
            <div class="grid grid-cols-2 gap-3">
              <div>
                <label class="block text-[10px] uppercase tracking-wider text-gray-500 font-black mb-1">Version ID</label>
                <input type="text" id="log-version" placeholder="e.g. v0.9.6" 
                       class="w-full bg-[#110d16] border border-red-900/40 rounded-lg py-2 px-3 text-sm focus:outline-none focus:border-red-600 text-white placeholder-gray-600 font-bold">
              </div>
              <div>
                <label class="block text-[10px] uppercase tracking-wider text-gray-500 font-black mb-1">Release Date</label>
                <input type="text" id="log-date" placeholder="Leave blank for today" 
                       class="w-full bg-[#110d16] border border-red-900/40 rounded-lg py-2 px-3 text-sm focus:outline-none focus:border-red-600 text-white placeholder-gray-600">
              </div>
            </div>
            
            <div>
              <label class="block text-[10px] uppercase tracking-wider text-gray-500 font-black mb-1">Release Title</label>
              <input type="text" id="log-title" placeholder="e.g. THE GOOPIAN STRIKES BACK UPDATE..." 
                     class="w-full bg-[#110d16] border border-red-900/40 rounded-lg py-2 px-3 text-sm focus:outline-none focus:border-red-600 text-white placeholder-gray-600 font-black uppercase">
            </div>

            <div>
              <label class="block text-[10px] uppercase tracking-wider text-gray-500 font-black mb-1 flex justify-between items-center">
                <span>Bullets / Features (One per line)</span>
                <span class="text-[9px] text-gray-600 normal-case">Shift + Enter for new lines</span>
              </label>
              <textarea id="log-items" rows="6" placeholder="Feature A...&#10;Feature B...&#10;Feature C..."
                        class="w-full bg-[#110d16] border border-red-900/40 rounded-lg py-2 px-3 text-sm focus:outline-none focus:border-red-600 text-white placeholder-gray-600 custom-scrollbar"></textarea>
            </div>

            <button onclick="saveChangelogEntry()" 
                    class="w-full bg-[#00e676] hover:bg-green-600 active:bg-green-700 text-black font-black py-2.5 px-4 rounded-lg text-xs tracking-wider uppercase transition duration-150 shadow-md">
              <i class="fa-solid fa-file-export mr-2"></i> Publish Release Notes
            </button>
          </div>
        </div>

        <!-- Current Changelog Feed Preview -->
        <div class="lg:col-span-7 bg-[#0c0910] rounded-xl retro-border p-5 overflow-y-auto max-h-[540px] custom-scrollbar">
          <h2 class="text-sm font-black text-red-500 uppercase tracking-wider mb-4 flex items-center gap-2">
            <i class="fa-solid fa-receipt text-[#ffd54f]"></i> assets/data/changelog.json
          </h2>
          <div id="changelog-list" class="space-y-6">
            <div class="text-gray-600 text-xs animate-pulse">Querying changelog file...</div>
          </div>
        </div>

      </div>
    </div>

    <!-- TAB 3: WIKI DATABASE EXPLORER -->
    <div id="tab-content-database" class="tab-pane hidden">
      <!-- Search Panel -->
      <div class="bg-[#1f1925] border border-red-950 rounded-xl p-5 mb-6 shadow-inner">
        <div class="flex flex-col md:flex-row gap-4 items-center">
          <div class="flex-1 w-full relative">
            <input type="text" id="db-search" oninput="filterDatabase()" placeholder="Type to search guns or items (e.g. Rusty, Casey, Spice)..." 
                   class="w-full bg-[#110d16] border border-red-900/40 rounded-xl py-3 pl-11 pr-4 text-sm focus:outline-none focus:border-red-600 text-white placeholder-gray-500 font-bold">
            <span class="absolute left-4 top-3.5 text-gray-500">
              <i class="fa-solid fa-magnifying-glass"></i>
            </span>
          </div>
          <!-- Type Filter -->
          <div class="flex gap-2 w-full md:w-auto">
            <button onclick="filterDbType('all')" id="db-filter-all" class="flex-1 md:flex-none px-4 py-2 bg-red-950/40 text-[#ffd54f] border border-red-900 text-xs font-black rounded-lg uppercase tracking-wider transition">All</button>
            <button onclick="filterDbType('guns')" id="db-filter-guns" class="flex-1 md:flex-none px-4 py-2 bg-transparent text-gray-400 hover:text-white border border-gray-800 text-xs font-black rounded-lg uppercase tracking-wider transition">Guns 🎯</button>
            <button onclick="filterDbType('items')" id="db-filter-items" class="flex-1 md:flex-none px-4 py-2 bg-transparent text-gray-400 hover:text-white border border-gray-800 text-xs font-black rounded-lg uppercase tracking-wider transition">Items 📦</button>
          </div>
        </div>
      </div>

      <!-- Live Filter Grid -->
      <div id="db-grid" class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4 overflow-y-auto max-h-[460px] p-2 custom-scrollbar">
        <div class="col-span-full text-center text-xs text-gray-500 py-12">
          <i class="fa-solid fa-spinner animate-spin text-red-500 text-2xl mb-2"></i>
          <div>Populating content index...</div>
        </div>
      </div>
    </div>

    <!-- TAB 4: TASKS MILESTONES -->
    <div id="tab-content-tasks" class="tab-pane hidden">
      <div class="grid grid-cols-1 lg:grid-cols-12 gap-8">
        
        <!-- Add Task Form -->
        <div class="lg:col-span-4 bg-[#1f1925] border border-red-950 rounded-xl p-5 shadow-inner">
          <h2 class="text-sm font-black text-red-500 uppercase tracking-wider mb-4 flex items-center gap-2">
            <i class="fa-solid fa-calendar-plus text-[#ffd54f]"></i> Create Task
          </h2>
          <div class="flex flex-col gap-4">
            <div>
              <label class="block text-[10px] uppercase tracking-wider text-gray-500 font-black mb-1">Task Description</label>
              <input type="text" id="task-text" placeholder="e.g. Verify Bluetooth match stability..." 
                     class="w-full bg-[#110d16] border border-red-900/40 rounded-lg py-2 px-3 text-sm focus:outline-none focus:border-red-600 text-white placeholder-gray-600">
            </div>
            
            <div>
              <label class="block text-[10px] uppercase tracking-wider text-gray-500 font-black mb-1">Priority</label>
              <select id="task-priority" class="w-full bg-[#110d16] border border-red-900/40 rounded-lg py-2 px-3 text-sm focus:outline-none focus:border-red-600 text-white font-bold">
                <option value="high" class="text-red-500 font-bold">🔥 High Priority</option>
                <option value="medium" class="text-amber-500 font-bold" selected>⚡ Medium Priority</option>
                <option value="low" class="text-cyan-500 font-bold">💤 Low Priority</option>
              </select>
            </div>

            <button onclick="addTask()" 
                    class="w-full bg-[#ffd54f] hover:bg-yellow-500 text-black font-black py-2.5 px-4 rounded-lg text-xs tracking-wider uppercase transition duration-150 shadow-md">
              <i class="fa-solid fa-add mr-2"></i> Add to Roadmap
            </button>
          </div>
        </div>

        <!-- Live Checklist -->
        <div class="lg:col-span-8 bg-[#0c0910] rounded-xl retro-border p-5 overflow-y-auto max-h-[540px] custom-scrollbar">
          <div class="flex justify-between items-center mb-4">
            <h2 class="text-sm font-black text-red-500 uppercase tracking-wider flex items-center gap-2">
              <i class="fa-solid fa-list-check text-green-400"></i> Active Project Roadmap
            </h2>
            <span id="task-count" class="px-2 py-0.5 bg-red-950 border border-red-900 text-[10px] font-bold rounded-md text-red-400">
              0 tasks
            </span>
          </div>
          <div id="tasks-list" class="space-y-3">
            <!-- Filled via JS -->
          </div>
        </div>

      </div>
    </div>

    <!-- TAB 5: BUGS & DIAGNOSTICS -->
    <div id="tab-content-bugs" class="tab-pane hidden">
      <div class="flex flex-col gap-6">
        <div class="bg-[#1f1925] border border-red-950 rounded-xl p-5 shadow-inner">
          <div class="flex justify-between items-center mb-4 border-b border-red-950/50 pb-3">
            <h2 class="text-sm font-black text-red-500 uppercase tracking-wider flex items-center gap-2 animate-pulse">
              <i class="fa-solid fa-triangle-exclamation"></i> Live App Bug Streams
            </h2>
            <button onclick="clearBugs()" class="bg-red-950/40 hover:bg-red-900 border border-red-900/60 hover:border-red-500 text-red-400 hover:text-white font-bold text-[10px] px-3 py-1 rounded-lg transition">
              RESOLVE & CLEAR ALL
            </button>
          </div>
          <p class="text-xs text-gray-500 leading-relaxed mb-4">
            Below are real-time, anonymous reports intercepted directly from GungeonMate running on your devices or emulators. 
            All submissions sync in real-time here so you can trace them without scanning manual system mail pipelines or Formspree dashboards.
          </p>

          <div id="bugs-list" class="space-y-4 max-h-[460px] overflow-y-auto pr-2 custom-scrollbar">
            <div class="text-center text-xs text-gray-600 py-12">
              <i class="fa-solid fa-shield-virus text-green-500 text-2xl mb-2"></i>
              <div>No bugs reported on this workspace session yet. Pristine!</div>
            </div>
          </div>
        </div>
      </div>
    </div>

  </div>

  <!-- Bottom Quote Footer -->
  <div class="text-center text-[10px] font-bold text-red-800 tracking-widest uppercase mt-6 mb-2">
    Professor Goopton's Multi-Tool Control Suite • GungeonMate v0.9.5
  </div>

  <script>
    // Globals
    let dbIndex = [];
    let currentFilterType = 'all';
    let currentTasks = [];
    let activeEventSource = null;

    // On Load
    window.addEventListener('DOMContentLoaded', () => {
      refreshVersion();
      loadChangelog();
      loadDatabase();
      loadTasks();
      loadBugs();
      
      // Auto-refresh bugs and version info every 4 seconds
      setInterval(() => {
        loadBugs();
        refreshVersion();
      }, 4000);
    });

    function refreshVersion() {
      fetch('/api/version')
        .then(res => res.json())
        .then(data => {
          document.getElementById('version-badge').innerText = 'v' + data.version;
        });
    }

    // Toggle overlay drawer menu
    function toggleDrawer(show) {
      const drawer = document.getElementById('control-drawer');
      const backdrop = document.getElementById('drawer-backdrop');
      if (show) {
        drawer.classList.remove('translate-x-full');
        backdrop.classList.remove('hidden');
      } else {
        drawer.classList.add('translate-x-full');
        backdrop.classList.add('hidden');
      }
    }

    // Tab switcher
    function switchTab(tabId) {
      document.querySelectorAll('.tab-pane').forEach(el => el.classList.add('hidden'));
      document.getElementById('tab-content-' + tabId).classList.remove('hidden');
      
      const tabButtons = ['bridge', 'changelog', 'database', 'tasks', 'bugs'];
      tabButtons.forEach(btn => {
        const el = document.getElementById('tab-btn-' + btn);
        if (btn === tabId) {
          el.className = "px-4 md:px-5 py-2.5 text-xs tracking-widest font-black uppercase border-b-2 border-red-600 text-white transition-all flex items-center gap-2";
        } else {
          el.className = "px-4 md:px-5 py-2.5 text-xs tracking-widest font-black uppercase border-b-2 border-transparent text-gray-500 hover:text-white transition-all flex items-center gap-2";
        }
      });
    }

    // TAB 1: CONSOLE STREAM ENGINE
    function appendToConsole(text, isErr = false, isCmd = false) {
      const consoleDiv = document.getElementById('console-output');
      const line = document.createElement('div');
      
      if (isErr) {
        line.className = 'text-red-500 font-bold';
        line.innerHTML = `<i class="fa-solid fa-triangle-exclamation mr-1.5"></i> ${text}`;
      } else if (isCmd) {
        line.className = 'text-[#ffd54f] font-black mt-2 border-t border-dashed border-red-900/20 pt-1.5 font-mono';
        line.innerHTML = `<i class="fa-solid fa-chevron-right mr-1.5"></i> ${text}`;
      } else if (text.includes('[EXIT]')) {
        line.className = 'text-green-400 font-bold my-1.5';
        line.innerHTML = `<i class="fa-solid fa-circle-check mr-1.5"></i> ${text}`;
      } else {
        line.className = 'text-[#a7ffd5]';
        line.innerText = text;
      }
      
      consoleDiv.appendChild(line);
      consoleDiv.scrollTop = consoleDiv.scrollHeight;
    }

    function clearConsole() {
      const consoleDiv = document.getElementById('console-output');
      consoleDiv.innerHTML = '<div class="text-[#ffd54f]/50 font-mono">===================================================</div><div class="text-[#ffd54f] font-mono">⚙️ Console cleared. Ready.</div><div class="text-[#ffd54f]/50 font-mono">===================================================</div>';
    }

    function triggerCommand(cmd) {
      if (activeEventSource) {
        appendToConsole("Another build process is actively running!", true);
        return;
      }

      const commitMsg = document.getElementById('commit-msg').value;
      if (cmd === 'git_commit' && !commitMsg.trim()) {
        appendToConsole("Commit message is required to commit!", true);
        return;
      }

      toggleDrawer(false); // Close commands drawer when running!
      setControlsState(false);
      appendToConsole(`SPAWNING BACKGROUND STREAM: ${cmd.toUpperCase()}...`, false, true);

      const url = `/api/run?cmd=${cmd}&msg=${encodeURIComponent(commitMsg)}`;
      activeEventSource = new EventSource(url);

      activeEventSource.onmessage = function(event) {
        const raw = event.data;
        if (raw === '[DONE]') {
          activeEventSource.close();
          activeEventSource = null;
          setControlsState(true);
          appendToConsole("Stream connection completed successfully.", false, true);
          refreshVersion();
          return;
        }

        if (raw.startsWith('stdout: ')) {
          appendToConsole(raw.substring(8));
        } else if (raw.startsWith('stderr: ')) {
          appendToConsole(raw.substring(8), true);
        } else {
          appendToConsole(raw);
        }
      };

      activeEventSource.onerror = function() {
        appendToConsole("Stream connection error. Forcing exit.", true);
        activeEventSource.close();
        activeEventSource = null;
        setControlsState(true);
      };
    }

    function bumpVersion(type) {
      const url = type === 'patch' ? '/api/bump-patch' : '/api/bump-minor';
      appendToConsole(`Writing atomic version bump to pubspec.yaml (type: ${type})...`, false, true);
      toggleDrawer(false);

      fetch(url)
        .then(res => res.json())
        .then(data => {
          document.getElementById('version-badge').innerText = 'v' + data.version;
          appendToConsole(`Version successfully bumped to: ${data.version}`);
        })
        .catch(err => {
          appendToConsole(`Failed to write version: ${err}`, true);
        });
    }

    // TAB 2: CHANGELOG BUILDER
    function loadChangelog() {
      fetch('/api/changelog')
        .then(res => res.json())
        .then(data => {
          const listDiv = document.getElementById('changelog-list');
          listDiv.innerHTML = '';
          
          if (data.length === 0) {
            listDiv.innerHTML = '<div class="text-gray-500 text-xs text-center py-10">No changelog entries found.</div>';
            return;
          }

          data.forEach(rel => {
            const card = document.createElement('div');
            card.className = 'border border-red-950/40 rounded-xl p-4 bg-[#141018]/50';
            
            let bullets = '';
            if (rel.items && rel.items.length > 0) {
              bullets = `<ul class="list-disc pl-5 mt-2.5 text-xs text-gray-400 space-y-1.5 leading-relaxed">` +
                rel.items.map(it => `<li>${it}</li>`).join('') +
                `</ul>`;
            }

            card.innerHTML = `
              <div class="flex justify-between items-start">
                <span class="px-2 py-0.5 bg-red-900/10 border border-red-900 text-red-400 text-xs font-black rounded font-mono">${rel.version}</span>
                <span class="text-[10px] text-gray-600 font-bold uppercase font-mono">${rel.date}</span>
              </div>
              <h3 class="text-sm font-black text-[#ffd54f] tracking-wide mt-2 uppercase">${rel.title}</h3>
              ${bullets}
            `;
            listDiv.appendChild(card);
          });
        });
    }

    function saveChangelogEntry() {
      const version = document.getElementById('log-version').value;
      const title = document.getElementById('log-title').value;
      const date = document.getElementById('log-date').value;
      const itemsRaw = document.getElementById('log-items').value;

      if (!version.trim() || !title.trim() || !itemsRaw.trim()) {
        alert("Please complete Version, Title, and Bullets fields!");
        return;
      }

      const items = itemsRaw.split('\n').map(it => it.trim()).filter(it => it.length > 0);
      const payload = { version, title, date, items };

      fetch('/api/changelog', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(payload)
      })
      .then(res => res.json())
      .then(data => {
        if (data.success) {
          document.getElementById('log-version').value = '';
          document.getElementById('log-title').value = '';
          document.getElementById('log-date').value = '';
          document.getElementById('log-items').value = '';
          
          loadChangelog();
          switchTab('changelog');
          alert("Notes added successfully to assets/data/changelog.json!");
        } else {
          alert("Failed to append changelog!");
        }
      });
    }

    // TAB 3: WIKI DATABASE INDEXER
    function loadDatabase() {
      fetch('/api/database')
        .then(res => res.json())
        .then(data => {
          dbIndex = data;
          filterDatabase();
        });
    }

    function filterDbType(type) {
      currentFilterType = type;
      ['all', 'guns', 'items'].forEach(f => {
        const el = document.getElementById('db-filter-' + f);
        if (f === type) {
          el.className = "flex-1 md:flex-none px-4 py-2 bg-red-950/40 text-[#ffd54f] border border-red-900 text-xs font-black rounded-lg uppercase tracking-wider transition";
        } else {
          el.className = "flex-1 md:flex-none px-4 py-2 bg-transparent text-gray-400 hover:text-white border border-gray-800 text-xs font-black rounded-lg uppercase tracking-wider transition";
        }
      });
      filterDatabase();
    }

    function filterDatabase() {
      const query = document.getElementById('db-search').value.toLowerCase();
      const grid = document.getElementById('db-grid');
      grid.innerHTML = '';

      let filtered = dbIndex;

      // Filter by gun vs item
      if (currentFilterType === 'guns') {
        filtered = filtered.filter(x => x.is_gun);
      } else if (currentFilterType === 'items') {
        filtered = filtered.filter(x => !x.is_gun);
      }

      // Filter by search query
      if (query.trim() !== '') {
        filtered = filtered.filter(x => 
          (x.name && x.name.toLowerCase().includes(query)) ||
          (x.notes && x.notes.toLowerCase().includes(query)) ||
          (x.quote && x.quote.toLowerCase().includes(query))
        );
      }

      if (filtered.length === 0) {
        grid.innerHTML = '<div class="col-span-full text-center text-xs text-gray-600 py-16">No matched master entries.</div>';
        return;
      }

      const displaySubset = filtered.slice(0, 45);

      displaySubset.forEach(x => {
        const card = document.createElement('div');
        
        let borderClass = 'border-gray-800 bg-[#141018]/40';
        let badgeColor = 'bg-gray-800 text-gray-300';
        const q = x.quality ? x.quality.toUpperCase() : 'N/A';
        
        if (q === 'S') { borderClass = 'border-yellow-600/50 bg-yellow-950/10'; badgeColor = 'bg-yellow-600/20 text-[#ffd54f] border border-yellow-500/40'; }
        else if (q === 'A') { borderClass = 'border-red-600/50 bg-red-950/10'; badgeColor = 'bg-red-600/20 text-red-400 border border-red-500/40'; }
        else if (q === 'B') { borderClass = 'border-indigo-600/50 bg-indigo-950/10'; badgeColor = 'bg-indigo-600/20 text-indigo-400 border border-indigo-500/40'; }
        else if (q === 'C') { borderClass = 'border-green-600/50 bg-green-950/10'; badgeColor = 'bg-green-600/20 text-green-400 border border-green-500/40'; }
        else if (q === 'D') { borderClass = 'border-blue-600/50 bg-blue-950/10'; badgeColor = 'bg-blue-600/20 text-blue-400 border border-blue-500/40'; }

        card.className = `border rounded-xl p-4 flex flex-col justify-between transition-all hover:scale-[1.01] hover:border-red-800/40 ${borderClass}`;
        
        const typeBadge = x.is_gun 
          ? `<span class="px-2 py-0.5 bg-red-900/10 border border-red-900/40 text-red-400 text-[9px] font-black tracking-wide uppercase rounded">Gun 🎯</span>`
          : `<span class="px-2 py-0.5 bg-blue-900/10 border border-blue-900/40 text-blue-400 text-[9px] font-black tracking-wide uppercase rounded">Item 📦</span>`;

        const dpsLabel = x.is_gun && x.dps 
          ? `<div class="mt-2 text-[10px] text-gray-500 font-bold font-mono">DPS: <span class="text-green-400">${x.dps}</span></div>` 
          : '';

        card.innerHTML = `
          <div>
            <div class="flex justify-between items-start gap-2">
              <span class="text-sm font-black text-white leading-snug">${x.name}</span>
              <div class="flex gap-1.5 items-center">
                ${typeBadge}
                <span class="px-1.5 py-0.5 font-black text-[9px] rounded font-mono ${badgeColor}">${q}</span>
              </div>
            </div>
            <div class="text-[10px] italic text-[#ffd54f]/80 font-bold mt-1 font-mono leading-tight">"${x.quote || ''}"</div>
            <p class="text-xs text-gray-400 mt-2 leading-relaxed line-clamp-3">${x.notes || 'No description notes available.'}</p>
            ${dpsLabel}
          </div>
        `;
        grid.appendChild(card);
      });

      if (filtered.length > 45) {
        const moreDiv = document.createElement('div');
        moreDiv.className = 'col-span-full text-center text-xs text-gray-600 py-4 font-bold uppercase tracking-wider';
        moreDiv.innerText = `+ ${filtered.length - 45} other matched entries. Refine search query.`;
        grid.appendChild(moreDiv);
      }
    }

    // TAB 4: TASKS ROADMAP CHECKLIST
    function loadTasks() {
      fetch('/api/tasks')
        .then(res => res.json())
        .then(data => {
          currentTasks = data;
          renderTasks();
        });
    }

    function renderTasks() {
      const list = document.getElementById('tasks-list');
      const countBadge = document.getElementById('task-count');
      list.innerHTML = '';
      
      countBadge.innerText = `${currentTasks.length} tasks`;

      if (currentTasks.length === 0) {
        list.innerHTML = '<div class="text-gray-500 text-xs text-center py-12">No active tasks in your backlog!</div>';
        return;
      }

      currentTasks.forEach((task, index) => {
        const el = document.createElement('div');
        
        let priorityBadge = '';
        if (task.priority === 'high') priorityBadge = '<span class="px-2 py-0.5 bg-red-950 border border-red-900 text-red-500 text-[9px] font-black uppercase tracking-wider rounded">High</span>';
        else if (task.priority === 'medium') priorityBadge = '<span class="px-2 py-0.5 bg-yellow-950 border border-yellow-900 text-yellow-500 text-[9px] font-black uppercase tracking-wider rounded">Medium</span>';
        else priorityBadge = '<span class="px-2 py-0.5 bg-cyan-950 border border-cyan-900 text-cyan-400 text-[9px] font-black uppercase tracking-wider rounded">Low</span>';

        const cardBg = task.done ? 'bg-[#141018]/20 opacity-50 border-gray-900' : 'bg-[#141018]/60 border-red-950/30';
        const textStyle = task.done ? 'line-through text-gray-500' : 'text-white';
        const checkIcon = task.done ? 'fa-square-check text-green-400' : 'fa-square text-gray-600 hover:text-white';

        el.className = `flex justify-between items-center p-3 border rounded-xl transition duration-150 ${cardBg}`;
        el.innerHTML = `
          <div class="flex items-center gap-3">
            <button onclick="toggleTask(${task.id})" class="text-lg transition flex items-center">
              <i class="fa-regular ${checkIcon}"></i>
            </button>
            <span class="text-xs font-bold ${textStyle}">${task.text}</span>
          </div>
          <div class="flex items-center gap-3">
            ${priorityBadge}
            <button onclick="deleteTask(${task.id})" class="text-red-950 hover:text-red-500 transition text-xs flex items-center">
              <i class="fa-solid fa-trash-can"></i>
            </button>
          </div>
        `;
        list.appendChild(el);
      });
    }

    function toggleTask(id) {
      currentTasks = currentTasks.map(t => {
        if (t.id === id) t.done = !t.done;
        return t;
      });
      syncTasks();
    }

    function addTask() {
      const text = document.getElementById('task-text').value;
      const priority = document.getElementById('task-priority').value;

      if (!text.trim()) {
        alert("Please write a task description!");
        return;
      }

      const newTask = {
        id: Date.now(),
        text: text.trim(),
        done: false,
        priority: priority
      };

      currentTasks.push(newTask);
      document.getElementById('task-text').value = '';
      syncTasks();
    }

    function deleteTask(id) {
      currentTasks = currentTasks.filter(t => t.id !== id);
      syncTasks();
    }

    function syncTasks() {
      fetch('/api/tasks', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ tasks: currentTasks })
      })
      .then(res => res.json())
      .then(data => {
        if (data.success) {
          currentTasks = data.tasks;
          renderTasks();
        }
      });
    }

    // TAB 5: BUGS & DIAGNOSTICS CONTROL
    function loadBugs() {
      fetch('/api/bugs')
        .then(res => res.json())
        .then(bugs => {
          const list = document.getElementById('bugs-list');
          const counter = document.getElementById('bug-tab-counter');
          
          if (bugs.length > 0) {
            counter.innerText = bugs.length;
            counter.classList.remove('hidden');
          } else {
            counter.classList.add('hidden');
          }

          if (bugs.length === 0) {
            list.innerHTML = `
              <div class="text-center text-xs text-gray-600 py-12">
                <i class="fa-solid fa-shield-virus text-green-500 text-2xl mb-2 animate-pulse"></i>
                <div>No bugs reported on this workspace session yet. Pristine!</div>
              </div>`;
            return;
          }

          list.innerHTML = '';
          bugs.forEach(bug => {
            const el = document.createElement('div');
            el.className = 'border border-red-900/30 rounded-xl p-4 bg-[#141018]/70 hover:border-red-800/60 transition';
            
            let categoryBadge = '';
            if (bug.category === 'UI/UX') categoryBadge = 'bg-blue-900/20 text-blue-400 border border-blue-900/50';
            else if (bug.category === 'Multiplayer') categoryBadge = 'bg-indigo-900/20 text-indigo-400 border border-indigo-900/50';
            else if (bug.category === 'Gun/Item') categoryBadge = 'bg-amber-900/20 text-[#ffd54f] border border-amber-900/50';
            else categoryBadge = 'bg-gray-800 text-gray-400 border border-gray-700/50';

            el.innerHTML = `
              <div class="flex justify-between items-start gap-4 mb-2">
                <div class="flex gap-2 items-center">
                  <span class="px-2 py-0.5 text-[9px] font-black uppercase rounded ${categoryBadge}">${bug.category}</span>
                  <span class="text-[9px] text-gray-600 font-bold font-mono">${bug.timestamp}</span>
                </div>
                <span class="text-[9px] bg-red-950/20 border border-red-900/40 text-red-500 px-2 py-0.5 rounded font-bold uppercase tracking-wider font-mono">
                  ${bug.app_version || 'v0.9.5'}
                </span>
              </div>
              <h4 class="text-sm font-black text-white flex items-center gap-1.5">
                <i class="fa-solid fa-circle-chevron-right text-red-500 text-xs"></i> 
                ${bug.target_entity !== 'N/A' ? bug.target_entity : 'General Code Feedback'}
              </h4>
              <p class="text-xs text-gray-300 mt-2 font-medium bg-black/40 border border-black p-3 rounded-lg leading-relaxed">${bug.feedback}</p>
              <div class="text-[9px] text-gray-600 font-bold mt-2 uppercase tracking-wide flex items-center gap-1">
                <i class="fa-solid fa-location-crosshairs text-gray-500"></i> Context Source: <span class="text-gray-400 font-mono italic select-all ml-1">${bug.launch_source || 'N/A'}</span>
              </div>
            `;
            list.appendChild(el);
          });
        });
    }

    function clearBugs() {
      if (!confirm("Are you sure you want to mark all reported bugs as resolved and clear the logs?")) return;
      
      fetch('/api/bugs/clear', { method: 'POST' })
        .then(res => res.json())
        .then(data => {
          loadBugs();
          alert("All live bug reports resolved and flushed from local logs!");
        });
    }

    function setControlsState(enabled) {
      const buttons = document.querySelectorAll('button');
      buttons.forEach(btn => {
        if (btn.innerText !== 'CLEAR') {
          btn.disabled = !enabled;
          if (enabled) {
            btn.classList.remove('opacity-40', 'cursor-not-allowed');
          } else {
            btn.classList.add('opacity-40', 'cursor-not-allowed');
          }
        }
      });
    }
  </script>
</body>
</html>
'''

if __name__ == '__main__':
    # Change working directory to the project root (parent directory of 'tool')
    os.chdir(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
    
    server_address = ('127.0.0.1', PORT)
    with socketserver.TCPServer(server_address, DevOpsHandler) as httpd:
        print('===========================================================')
        print(f'🔥 GungeonMate DevOps Server running at: http://localhost:{PORT}')
        print('👉 Open this URL in your web browser to run the DevOps panel!')
        print('===========================================================')
        try:
            httpd.serve_forever()
        except KeyboardInterrupt:
            print('\nStopping DevOps server...')
            sys.exit(0)
