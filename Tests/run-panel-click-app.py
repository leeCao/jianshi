from pathlib import Path
import argparse
import plistlib
import os
import subprocess

parser = argparse.ArgumentParser()
parser.add_argument('--build-only', action='store_true')
args = parser.parse_args()
root = Path(__file__).resolve().parents[1]
output = root / '.build' / 'click-smoke'
app = output / 'MenuminderClickTest.app'
macos = app / 'Contents' / 'MacOS'
macos.mkdir(parents=True, exist_ok=True)
bundle = output / 'Bundle.swift'
bundle.write_text('import Foundation\nextension Bundle { static let module = Bundle(path: "' + str(root / 'Sources/Menuminder') + '")! }\n')
sources = [str(p) for p in (root / 'Sources/Menuminder').glob('*.swift') if p.name != 'MenuminderApp.swift']
sdk = os.environ.get('SDKROOT')
if not sdk:
    compatible = Path('/Library/Developer/CommandLineTools/SDKs/MacOSX26.5.sdk')
    sdk = str(compatible) if compatible.exists() and subprocess.check_output(['xcode-select', '-p'], text=True).strip() == '/Library/Developer/CommandLineTools' else subprocess.check_output(['xcrun', '--show-sdk-path'], text=True).strip()
subprocess.run(['swiftc', '-parse-as-library', '-sdk', sdk, '-module-cache-path', str(root / '.build/design-preview-module-cache'), *sources, str(bundle), str(root / 'Tests/PanelClickApp.swift'), '-o', str(macos / 'MenuminderClickTest')], check=True)
(app / 'Contents' / 'Info.plist').write_bytes(plistlib.dumps({
    'CFBundleExecutable': 'MenuminderClickTest',
    'CFBundleIdentifier': 'com.local.MenuminderClickTest',
    'CFBundleName': 'MenuminderClickTest',
    'CFBundlePackageType': 'APPL',
    'NSHighResolutionCapable': True,
}))
if not args.build_only:
    subprocess.run([str(macos / 'MenuminderClickTest'), str(output)], check=True)
