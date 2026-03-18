# Code Snippets for Console

Console snippets for quickly loading multi-clone presets into Abecedarium.
Paste into Chrome DevTools console after the page has loaded.

---

## Clone Multi-Tests

### 10 layers — stroke only, random Gaussian 5–15

```js
loadPreset({
  char: 'a',
  clones: Array.from({ length: 10 }, () => ({
    fillOn: false,
    strokeOn: true,
    noise: { independent: { enabled: true, params: {
      gaussAmt: +(5 + Math.random() * 10).toFixed(1)
    }}}
  }))
});
```
