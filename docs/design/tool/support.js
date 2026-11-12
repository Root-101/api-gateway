// Minimal stand-in for the Design canvas runtime, only to screenshot artboards: runs the
// artboard's renderVals() with its default props and expands sc-if, sc-for, {{holes}} and
// dc-import. Not the real runtime.
class DCLogic {
  constructor(props) { this.props = props; this.state = {}; }
  setState() {}
}
window.DCLogic = DCLogic;

function defaults(propsJson, extra) {
  const props = {};
  for (const [k, v] of Object.entries(JSON.parse(propsJson || '{}'))) {
    if (!k.startsWith('$') && v && 'default' in v) props[k] = v.default;
  }
  return Object.assign(props, extra || {});
}

function lookup(expr, scope) {
  expr = expr.trim();
  if (expr === 'true') return true;
  if (expr === 'false') return false;
  return expr.split('.').reduce((o, k) => (o == null ? undefined : o[k]), scope);
}

function fill(text, scope) {
  return text.replace(/\{\{([^}]*)\}\}/g, (_, e) => {
    const v = lookup(e, scope);
    return v == null || typeof v === 'function' ? '' : String(v);
  });
}

async function renderNodes(nodes, scope, out) {
  for (let node of nodes) {
    if (node.nodeType === Node.TEXT_NODE) {
      out.appendChild(document.createTextNode(fill(node.textContent, scope)));
    } else if (node.nodeType === Node.ELEMENT_NODE) {
      let tag = node.tagName.toLowerCase();
      if (tag === 'template' && node.dataset.sc) {
        tag = node.dataset.sc;
        const el = node;
        node = { getAttribute: (n) => el.getAttribute(n), childNodes: el.content.childNodes };
      }
      if (tag === 'sc-if') {
        const m = (node.getAttribute('value') || '').match(/\{\{([^}]*)\}\}/);
        if (m && lookup(m[1], scope)) await renderNodes(node.childNodes, scope, out);
      } else if (tag === 'sc-for') {
        const m = (node.getAttribute('list') || '').match(/\{\{([^}]*)\}\}/);
        const as = node.getAttribute('as');
        for (const item of (m && lookup(m[1], scope)) || []) {
          await renderNodes(node.childNodes, Object.assign({}, scope, { [as]: item }), out);
        }
      } else if (tag === 'dc-import') {
        const extra = {};
        for (const a of node.attributes) {
          if (a.name === 'name' || a.name.startsWith('hint-')) continue;
          // A whole {{hole}} keeps its type (a boolean, a list); anything else is text
          const whole = a.value.match(/^\{\{([^}]*)\}\}$/);
          const value = whole ? lookup(whole[1], scope) : fill(a.value, scope);
          // The attribute is kebab-case, the prop it sets camelCase (start-screen → startScreen)
          const prop = a.name.replace(/-([a-z])/g, (_, c) => c.toUpperCase());
          extra[prop] = value === 'true' ? true : value === 'false' ? false : value;
        }
        out.appendChild(await renderFile(node.getAttribute('name') + '.dc.html', extra));
      } else {
        const svg = 'http://www.w3.org/2000/svg';
        const el = node.namespaceURI === svg
          ? document.createElementNS(svg, node.localName)
          : document.createElement(tag === 'helmet' ? 'div' : tag);
        for (const a of node.attributes) {
          if (/^on[A-Z]/.test(a.name)) continue;
          el.setAttribute(a.name, fill(a.value, scope));
        }
        await renderNodes(node.childNodes, scope, el);
        out.appendChild(el);
      }
    }
  }
}

async function renderDoc(doc, extra) {
  const script = doc.querySelector('script[data-dc-script]');
  const props = defaults(script.getAttribute('data-props'), extra);
  const Component = new Function('DCLogic', script.textContent + '\nreturn Component;')(DCLogic);
  const vals = new Component(props).renderVals();
  const helmet = doc.querySelector('x-dc > helmet');
  if (helmet) for (const n of [...helmet.childNodes]) document.head.appendChild(document.importNode(n, true));
  const frag = document.createDocumentFragment();
  const nodes = [...doc.querySelector('x-dc').childNodes].filter((n) => n.nodeName.toLowerCase() !== 'helmet');
  await renderNodes(nodes, vals, frag);
  return frag;
}

async function renderFile(name, extra) {
  // sc-if and sc-for as <template>: an unknown tag inside a <table> is moved out of it by the
  // HTML parser, a <template> stays where it is with its rows
  const text = (await (await fetch(name)).text())
    .replace(/<(sc-if|sc-for)\b/g, '<template data-sc="$1"')
    .replace(/<\/(sc-if|sc-for)>/g, '</template>');
  return renderDoc(new DOMParser().parseFromString(text, 'text/html'), extra);
}

window.addEventListener('DOMContentLoaded', async () => {
  const source = new DOMParser().parseFromString(document.documentElement.outerHTML, 'text/html');
  // Props from the query (?state=error&menu=true), to shoot an artboard in another state
  const extra = {};
  for (const [k, v] of new URLSearchParams(location.search)) {
    extra[k] = v === 'true' ? true : v === 'false' ? false : v;
  }
  const frag = await renderDoc(source, extra);
  document.body.innerHTML = '';
  document.body.appendChild(frag);
  // A still: entry animations (the fade-in of a dialog) caught halfway look transparent
  const still = document.createElement('style');
  still.textContent = '*,*::before,*::after{animation:none !important;transition:none !important}';
  document.head.appendChild(still);
  await document.fonts.ready;
  document.title = 'rendered';
});
