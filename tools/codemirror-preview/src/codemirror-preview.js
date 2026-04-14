import {defaultKeymap, indentWithTab} from "@codemirror/commands";
import {cpp} from "@codemirror/lang-cpp";
import {css} from "@codemirror/lang-css";
import {html} from "@codemirror/lang-html";
import {java} from "@codemirror/lang-java";
import {javascript} from "@codemirror/lang-javascript";
import {json} from "@codemirror/lang-json";
import {markdown} from "@codemirror/lang-markdown";
import {php} from "@codemirror/lang-php";
import {python} from "@codemirror/lang-python";
import {rust} from "@codemirror/lang-rust";
import {sql} from "@codemirror/lang-sql";
import {xml} from "@codemirror/lang-xml";
import {yaml} from "@codemirror/lang-yaml";
import {
  bracketMatching,
  defaultHighlightStyle,
  foldGutter,
  HighlightStyle,
  indentOnInput,
  syntaxHighlighting,
  StreamLanguage
} from "@codemirror/language";
import {highlightSelectionMatches, searchKeymap} from "@codemirror/search";
import {EditorState} from "@codemirror/state";
import {
  drawSelection,
  dropCursor,
  EditorView,
  highlightActiveLine,
  highlightActiveLineGutter,
  highlightSpecialChars,
  keymap,
  lineNumbers,
  rectangularSelection
} from "@codemirror/view";
import {tags as t} from "@lezer/highlight";
import {cmake} from "@codemirror/legacy-modes/mode/cmake";
import {diff} from "@codemirror/legacy-modes/mode/diff";
import {dockerFile} from "@codemirror/legacy-modes/mode/dockerfile";
import {go} from "@codemirror/legacy-modes/mode/go";
import {lua} from "@codemirror/legacy-modes/mode/lua";
import {perl} from "@codemirror/legacy-modes/mode/perl";
import {powerShell} from "@codemirror/legacy-modes/mode/powershell";
import {properties} from "@codemirror/legacy-modes/mode/properties";
import {ruby} from "@codemirror/legacy-modes/mode/ruby";
import {shell} from "@codemirror/legacy-modes/mode/shell";
import {swift} from "@codemirror/legacy-modes/mode/swift";

const editorFont = [
  "SFMono-Regular",
  "ui-monospace",
  "Menlo",
  "Monaco",
  "Consolas",
  "\"Liberation Mono\"",
  "monospace"
].join(", ");

const lightHighlightStyle = HighlightStyle.define([
  {tag: t.keyword, color: "#cf222e"},
  {tag: [t.name, t.deleted, t.character, t.propertyName, t.macroName], color: "#116329"},
  {tag: [t.function(t.variableName), t.labelName], color: "#8250df"},
  {tag: [t.color, t.constant(t.name), t.standard(t.name)], color: "#0550ae"},
  {tag: [t.definition(t.name), t.separator], color: "#24292f"},
  {tag: [t.typeName, t.className, t.number, t.changed, t.annotation, t.modifier, t.self, t.namespace], color: "#953800"},
  {tag: [t.operator, t.operatorKeyword, t.url, t.escape, t.regexp, t.link, t.special(t.string)], color: "#0550ae"},
  {tag: [t.meta, t.comment], color: "#6e7781"},
  {tag: t.strong, fontWeight: "600"},
  {tag: t.emphasis, fontStyle: "italic"},
  {tag: t.strikethrough, textDecoration: "line-through"},
  {tag: t.link, color: "#0969da", textDecoration: "underline"},
  {tag: t.heading, fontWeight: "600", color: "#24292f"},
  {tag: [t.atom, t.bool, t.special(t.variableName)], color: "#0550ae"},
  {tag: [t.processingInstruction, t.string, t.inserted], color: "#0a3069"},
  {tag: t.invalid, color: "#82071e", backgroundColor: "#ffebe9"}
]);

const darkHighlightStyle = HighlightStyle.define([
  {tag: t.keyword, color: "#ff7b72"},
  {tag: [t.name, t.deleted, t.character, t.propertyName, t.macroName], color: "#7ee787"},
  {tag: [t.function(t.variableName), t.labelName], color: "#d2a8ff"},
  {tag: [t.color, t.constant(t.name), t.standard(t.name)], color: "#79c0ff"},
  {tag: [t.definition(t.name), t.separator], color: "#c9d1d9"},
  {tag: [t.typeName, t.className, t.number, t.changed, t.annotation, t.modifier, t.self, t.namespace], color: "#ffa657"},
  {tag: [t.operator, t.operatorKeyword, t.url, t.escape, t.regexp, t.link, t.special(t.string)], color: "#79c0ff"},
  {tag: [t.meta, t.comment], color: "#8b949e"},
  {tag: t.strong, fontWeight: "600"},
  {tag: t.emphasis, fontStyle: "italic"},
  {tag: t.strikethrough, textDecoration: "line-through"},
  {tag: t.link, color: "#58a6ff", textDecoration: "underline"},
  {tag: t.heading, fontWeight: "600", color: "#c9d1d9"},
  {tag: [t.atom, t.bool, t.special(t.variableName)], color: "#79c0ff"},
  {tag: [t.processingInstruction, t.string, t.inserted], color: "#a5d6ff"},
  {tag: t.invalid, color: "#ffdcd7", backgroundColor: "#67060c"}
]);

const lightTheme = EditorView.theme({
  "&": {
    color: "#1f2328",
    backgroundColor: "#ffffff",
    height: "100%",
    minHeight: "100vh"
  },
  ".cm-scroller": {
    fontFamily: editorFont,
    fontSize: "13px",
    lineHeight: "20px",
    overflow: "auto"
  },
  ".cm-content": {
    caretColor: "transparent",
    minHeight: "100vh",
    padding: "13px 0"
  },
  ".cm-line": {
    padding: "0 28px 0 16px"
  },
  ".cm-gutters": {
    backgroundColor: "#fbfbfb",
    borderRight: "1px solid #e6e8eb",
    color: "#8c959f"
  },
  ".cm-lineNumbers .cm-gutterElement": {
    minWidth: "38px",
    padding: "0 12px 0 8px"
  },
  ".cm-activeLine": {
    backgroundColor: "#f6f8fa"
  },
  ".cm-activeLineGutter": {
    backgroundColor: "#f6f8fa",
    color: "#1f2328"
  },
  ".cm-selectionBackground, .cm-content ::selection": {
    backgroundColor: "rgba(0, 95, 184, 0.22) !important"
  },
  ".cm-cursor, .cm-dropCursor": {
    display: "none"
  },
  ".cm-matchingBracket": {
    backgroundColor: "rgba(9, 105, 218, 0.12)",
    outline: "1px solid rgba(9, 105, 218, 0.35)"
  },
  ".cm-searchMatch": {
    backgroundColor: "rgba(255, 212, 59, 0.35)",
    outline: "1px solid rgba(191, 135, 0, 0.35)"
  }
}, {dark: false});

const darkTheme = EditorView.theme({
  "&": {
    color: "#d4d4d4",
    backgroundColor: "#1e1e1e",
    height: "100%",
    minHeight: "100vh"
  },
  ".cm-scroller": {
    fontFamily: editorFont,
    fontSize: "13px",
    lineHeight: "20px",
    overflow: "auto"
  },
  ".cm-content": {
    caretColor: "transparent",
    minHeight: "100vh",
    padding: "13px 0"
  },
  ".cm-line": {
    padding: "0 28px 0 16px"
  },
  ".cm-gutters": {
    backgroundColor: "#1e1e1e",
    borderRight: "1px solid #2d2d2d",
    color: "#858585"
  },
  ".cm-lineNumbers .cm-gutterElement": {
    minWidth: "38px",
    padding: "0 12px 0 8px"
  },
  ".cm-activeLine": {
    backgroundColor: "#252526"
  },
  ".cm-activeLineGutter": {
    backgroundColor: "#252526",
    color: "#d4d4d4"
  },
  ".cm-selectionBackground, .cm-content ::selection": {
    backgroundColor: "rgba(38, 79, 120, 0.92) !important"
  },
  ".cm-cursor, .cm-dropCursor": {
    display: "none"
  },
  ".cm-matchingBracket": {
    backgroundColor: "rgba(88, 166, 255, 0.18)",
    outline: "1px solid rgba(88, 166, 255, 0.42)"
  },
  ".cm-searchMatch": {
    backgroundColor: "rgba(187, 128, 9, 0.42)",
    outline: "1px solid rgba(210, 153, 34, 0.40)"
  }
}, {dark: true});

function languageExtension(languageId) {
  switch (languageId) {
    case "bash":
      return StreamLanguage.define(shell);
    case "c":
    case "cpp":
      return cpp();
    case "cmake":
      return StreamLanguage.define(cmake);
    case "css":
      return css();
    case "diff":
      return StreamLanguage.define(diff);
    case "dockerfile":
      return StreamLanguage.define(dockerFile);
    case "go":
      return StreamLanguage.define(go);
    case "html":
      return html();
    case "java":
      return java();
    case "javascript":
      return javascript({jsx: false, typescript: false});
    case "jsx":
      return javascript({jsx: true, typescript: false});
    case "json":
      return json();
    case "lua":
      return StreamLanguage.define(lua);
    case "markdown":
      return markdown();
    case "perl":
      return StreamLanguage.define(perl);
    case "php":
      return php();
    case "powershell":
      return StreamLanguage.define(powerShell);
    case "properties":
      return StreamLanguage.define(properties);
    case "python":
      return python();
    case "ruby":
      return StreamLanguage.define(ruby);
    case "rust":
      return rust();
    case "sql":
      return sql();
    case "swift":
      return StreamLanguage.define(swift);
    case "tsx":
      return javascript({jsx: true, typescript: true});
    case "typescript":
      return javascript({jsx: false, typescript: true});
    case "xml":
      return xml();
    case "yaml":
      return yaml();
    default:
      return [];
  }
}

function buildExtensions(options) {
  const isDark = options.theme === "dark";
  const language = options.usesSyntaxHighlighting
    ? languageExtension(options.language)
    : [];

  return [
    lineNumbers(),
    highlightActiveLineGutter(),
    highlightSpecialChars(),
    foldGutter({
      markerDOM: open => {
        const marker = document.createElement("span");
        marker.textContent = open ? "⌄" : "›";
        marker.style.fontSize = "12px";
        marker.style.opacity = "0.72";
        return marker;
      }
    }),
    drawSelection(),
    dropCursor(),
    EditorState.readOnly.of(true),
    EditorState.tabSize.of(4),
    EditorView.contentAttributes.of({"aria-label": "File preview"}),
    indentOnInput(),
    bracketMatching(),
    rectangularSelection(),
    highlightActiveLine(),
    highlightSelectionMatches(),
    keymap.of([indentWithTab, ...defaultKeymap, ...searchKeymap]),
    language,
    syntaxHighlighting(isDark ? darkHighlightStyle : lightHighlightStyle),
    syntaxHighlighting(defaultHighlightStyle, {fallback: true}),
    isDark ? darkTheme : lightTheme
  ];
}

function mount(parent, options = {}) {
  const target = parent || document.getElementById("editor");
  if (!target) return null;

  if (window.cmuxCodeMirrorView) {
    window.cmuxCodeMirrorView.destroy();
    window.cmuxCodeMirrorView = null;
  }

  target.textContent = "";
  const state = EditorState.create({
    doc: options.content || "",
    extensions: buildExtensions(options)
  });

  const view = new EditorView({state, parent: target});
  window.cmuxCodeMirrorView = view;
  document.documentElement.classList.add("cmux-codemirror-ready");
  return view;
}

window.CmuxCodeMirror = {mount};
