import json, subprocess, os, sys

def run(cmd):
    return subprocess.run(cmd, capture_output=True, text=True)

def run_bin(cmd):
    return subprocess.run(cmd, capture_output=True)

os.makedirs("Screenshots", exist_ok=True)

result = run(["xcrun", "xcresulttool", "get", "--path", "UITestResults.xcresult", "--format", "json"])
if result.returncode != 0:
    print("Could not read xcresult:", result.stderr)
    sys.exit(0)

data = json.loads(result.stdout)
count = 0

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
            img = run_bin(["xcrun", "xcresulttool", "get", "--path", "UITestResults.xcresult", "--id", ref])
            fname = f"Screenshots/{name}.png"
            with open(fname, "wb") as f:
                f.write(img.stdout)
            print(f"Saved: {fname}")
            count += 1
    for v in obj.values():
        find_attachments(v, depth+1)

find_attachments(data)
print(f"Total screenshots extracted: {count}")
