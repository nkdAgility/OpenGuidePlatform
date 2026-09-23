-- Render Hugo/Obsidian-style callouts as tcolorbox environments in PDF output.
--   > [!NOTE] Optional title
--   > Body...
-- Adapted from ScrumGuide-ExpansionPack scripts/callouts-latex.lua. Default
-- titles come from the translated labels in the PDF metadata (labels.callout_*),
-- titles are rendered through Pandoc so they are escaped correctly, and emoji
-- icons are omitted because the configured document fonts rarely contain them.
-- The companion callouts.tex supplies the preamble.

local styles = {
  note = {back = "cyan!5", frame = "cyan!50!blue"},
  tip = {back = "green!5", frame = "green!50!black"},
  important = {back = "yellow!10", frame = "yellow!50!orange"},
  warning = {back = "orange!10", frame = "orange!50!red"},
  caution = {back = "red!10", frame = "red!50!black"},
  highlight = {back = "gray!5", frame = "gray!30"},
}

local function marker(inlines)
  if not inlines or #inlines == 0 or inlines[1].t ~= "Str" then return nil end
  return inlines[1].text:match("^%[!([A-Za-z0-9_-]+)%]")
end

local function latex_inline(inlines)
  local doc = pandoc.Pandoc({pandoc.Plain(inlines)})
  return (pandoc.write(doc, "latex"):gsub("%s+$", ""))
end

local function callout(el, labels)
  local first = el.content[1]
  if not first or first.t ~= "Para" then return nil end
  local kind = marker(first.content)
  if not kind then return nil end
  kind = kind:lower()
  local style = styles[kind] or styles.note

  -- The title is the rest of the marker line; later lines of the same
  -- paragraph belong to the body.
  local title_inlines, body_inlines = pandoc.List(), pandoc.List()
  local in_body = false
  for i = 2, #first.content do
    local inline = first.content[i]
    if not in_body and (inline.t == "SoftBreak" or inline.t == "LineBreak") then
      in_body = true
    elseif in_body then
      body_inlines:insert(inline)
    else
      title_inlines:insert(inline)
    end
  end
  while #title_inlines > 0 and title_inlines[1].t == "Space" do title_inlines:remove(1) end
  local title = latex_inline(title_inlines)
  if title == "" and kind ~= "highlight" then
    local label = labels["callout_" .. kind] or labels["callout_note"]
    title = label and latex_inline(pandoc.Inlines(pandoc.utils.stringify(label))) or ""
  end

  local options = string.format("colback=%s,colframe=%s", style.back, style.frame)
  if title ~= "" then options = options .. ",title={" .. title .. "}" end

  local blocks = pandoc.List({pandoc.RawBlock("latex", "\\begin{tcolorbox}[" .. options .. "]")})
  if #body_inlines > 0 then blocks:insert(pandoc.Para(body_inlines)) end
  for i = 2, #el.content do blocks:insert(el.content[i]) end
  blocks:insert(pandoc.RawBlock("latex", "\\end{tcolorbox}"))
  return blocks
end

function Pandoc(doc)
  if not FORMAT:match("latex") then return nil end
  local labels = {}
  if doc.meta.labels then
    for key, value in pairs(doc.meta.labels) do labels[key] = value end
  end
  return doc:walk({BlockQuote = function(el) return callout(el, labels) end})
end
