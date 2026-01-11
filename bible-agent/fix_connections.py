# -*- coding: utf-8 -*-
import json
import io

with io.open('C:/Interesting/repos/rag/bible-agent/Bible Quotations.json', 'r', encoding='utf-8') as f:
    data = json.load(f)

# Fix the trigger connection
# Find the exact key name  
trigger_key = [k for k in data['connections'].keys() if 'Execute' in k][0]
data['connections'][trigger_key]['main'][0] = [
    {
        "node": "HTTP Request - Download Bible PDF",
        "type": "main",
        "index": 0
    },
    {
        "node": u"🇷🇺 Download Russian Bible PDF",
        "type": "main",
        "index": 0
    }
]

with io.open('C:/Interesting/repos/rag/bible-agent/Bible Quotations.json', 'w', encoding='utf-8') as f:
    output = json.dumps(data, ensure_ascii=False, indent=4)
    f.write(unicode(output))

print("Fixed trigger connection!")
