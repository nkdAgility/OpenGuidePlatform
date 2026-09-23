-- Keep Latin text in its own order inside right-to-left PDFs.
-- XeTeX's right-to-left handling does not reorder runs of Latin words, so
-- "(Knowledge Work)" inside Persian text would print as "Work) (Knowledge".
-- In documents whose metadata sets dir: rtl, this filter marks each run of
-- Latin text as English (Pandoc writes \foreignlanguage{english}{...}) and
-- each paragraph with no right-to-left letters as an English block.
-- Other documents are returned unchanged.

local rtl_pattern = "[\216-\219]"   -- UTF-8 lead bytes of U+0600..U+06FF (Arabic script)
local rtl_extra = {"\239\173", "\239\174", "\239\175", "\239\176", "\239\177", "\239\178", "\239\179", "\239\180", "\239\181", "\239\182", "\239\183", "\239\185", "\239\186", "\239\187"}

local function has_rtl(text)
  if text:find(rtl_pattern) then return true end
  -- Hebrew (U+0590..U+05FF) and Arabic presentation forms (U+FB50..U+FEFF)
  if text:find("\214[\144-\191]") or text:find("\215") then return true end
  for _, prefix in ipairs(rtl_extra) do
    if text:find(prefix, 1, true) then return true end
  end
  return false
end

local function has_latin(text)
  return text:find("[A-Za-z]") ~= nil
end

local function classify(inline)
  if inline.t == "Space" or inline.t == "SoftBreak" or inline.t == "LineBreak" then return "N" end
  local text = pandoc.utils.stringify(inline)
  if has_rtl(text) then return "R" end
  if has_latin(text) then return "L" end
  return "N"
end

local function mark_latin_runs(inlines)
  local result = pandoc.List()
  local i, n = 1, #inlines
  while i <= n do
    if classify(inlines[i]) == "L" then
      -- Extend over Latin items and the neutral items between them.
      local last = i
      local j = i + 1
      while j <= n do
        local kind = classify(inlines[j])
        if kind == "R" then break end
        if kind == "L" then last = j end
        j = j + 1
      end
      local run = pandoc.List()
      for k = i, last do run:insert(inlines[k]) end
      result:insert(pandoc.Span(run, pandoc.Attr("", {}, {lang = "en"})))
      i = last + 1
    else
      result:insert(inlines[i])
      i = i + 1
    end
  end
  return result
end

local function latin_only(block)
  local text = pandoc.utils.stringify(block)
  return has_latin(text) and not has_rtl(text)
end

function Pandoc(doc)
  if pandoc.utils.stringify(doc.meta.dir or "") ~= "rtl" then return nil end
  -- Only the body: metadata (babel options, cover values) must stay untouched.
  local blocks = doc.blocks:walk({
    Para = function(el)
      if latin_only(el) then return pandoc.Div({el}, pandoc.Attr("", {}, {lang = "en"})) end
      return nil
    end,
  })
  -- Nested marks (an English span inside an English block) are harmless.
  blocks = blocks:walk({Inlines = mark_latin_runs})
  return pandoc.Pandoc(blocks, doc.meta)
end
