# docs / diagrams

Graphviz diagrams. Each one has a `.dot` source plus `.png` and `.svg` renders. Edit the `.dot`, then re-render:

```bash
dot -Tsvg x.dot -o x.svg && dot -Tpng x.dot -o x.png
```

| Diagram | Shows | Current? |
| --- | --- | --- |
| `bootstrap-flow` | the iq9 bootstrap sequence | iq9-era |
| `fort-knox-defense` | layered defenses (Cloud Armor → IAP → ...) | iq9-era |
| `secure-dev-workflow` | the PR → review → apply workflow | current idea |
