import json

artifact_path = "/home/graham/.codewhale/sessions/eaadc023-20a0-4d45-a30a-e4a1e2052e20/artifacts/art_call_00_wzFnQANN1kKfMFzjbuCq3658.txt"
output_path = "/home/graham/dev/stream/allspeak.js"

with open(artifact_path, "r") as f:
    data = json.load(f)

js_content = data["content"]

with open(output_path, "w") as f:
    f.write(js_content)

# verify
with open(output_path, "r") as f:
    first_line = f.readline()
    f.seek(0, 2)
    size = f.tell()

print(f"Lines: {len(js_content.splitlines())}")
print(f"Bytes: {size}")
print(f"First 80 chars: {first_line[:80]}")
