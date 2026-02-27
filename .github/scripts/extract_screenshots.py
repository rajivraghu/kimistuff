import json, subprocess, os, sys

def run(cmd):
    return subprocess.run(cmd, capture_output=True, text=True)

def run_bin(cmd):
    return subprocess.run(cmd, capture_output=True)

os.makedirs("Screenshots", exist_ok=True)

xcresult_path = "UITestResults.xcresult"

if not os.path.exists(xcresult_path):
    print("UITestResults.xcresult not found - UI tests may have been skipped")
    sys.exit(0)

# Try new API first (Xcode 16+), fall back to legacy (Xcode 26 RC)
result = run(["xcrun", "xcresulttool", "get", "object", "--path", xcresult_path, "--format", "json"])
if result.returncode != 0:
    # Fall back to legacy flag required by Xcode 26
    result = run(["xcrun", "xcresulttool", "get", "--legacy", "--path", xcresult_path, "--format", "json"])
if result.returncode != 0:
    print("Could not read xcresult:", result.stderr)
    sys.exit(0)

data = json.loads(result.stdout)
count = 0

def extract_attachment(ref, name):
    # Try new API first
    img = run_bin(["xcrun", "xcresulttool", "get", "object", "--path", xcresult_path, "--id", ref])
    if img.returncode != 0:
        img = run_bin(["xcrun", "xcresulttool", "get", "--legacy", "--path", xcresult_path, "--id", ref])
    return img

def find_attachments(obj, depth=0):
    global count
    if depth > 20 or not isinstance(obj, (dict, list)):
        return
    if isinstance(obj, list):
        for item in obj:
            find_attachments(item, depth+1)
        return
    type_name = obj.get("_type", {}).get("_name", "")
    if type_name == "ActionTestAttachment":
        name = obj.get("name", {}).get("_value", f"screenshot_{count}")
        uti = obj.get("uniformTypeIdentifier", {}).get("_value", "")
        ref = obj.get("payloadRef", {}).get("id", {}).get("_value", "")
        if ref and "png" in uti:
            img = extract_attachment(ref, name)
            fname = f"Screenshots/{name}.png"
            with open(fname, "wb") as f:
                f.write(img.stdout)
            print(f"Saved: {fname}")
            count += 1
    for v in obj.values():
        find_attachments(v, depth+1)

find_attachments(data)
print(f"Total screenshots extracted: {count}")
