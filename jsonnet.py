import _jsonnet
import json
import jinja2


with open('tender.json') as _in:
    tender = _in.read()

with open('ocds.jsonnet') as _in:
    template = jinja2.Template(_in.read())

for _ in range(100):
    snippet = template.render(context=tender)

    print(_jsonnet.evaluate_snippet(
        'snippet',
        snippet
    ))
