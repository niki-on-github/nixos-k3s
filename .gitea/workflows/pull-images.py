import re
import subprocess

with open('flux-diff.md') as f:
    for line in f:
        if m := re.match(r'^\+\s*image:\s*(\S+)', line):
            image = m.group(1)
            print('pull image:', image)
            subprocess.run([
                "curl", "-s", "-X", "POST",
                "http://image-puller.system.svc.cluster.local/pull-image",
                "-H", "Content-Type: application/json",
                "-d", f'{{"image": "{image}"}}'
            ])
