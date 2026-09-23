-- Hugo pages reference site-root images as "/images/x.png". Strip the leading
-- slash so Pandoc resolves them through --resource-path.
-- Adapted from ScrumGuide-ExpansionPack scripts/callouts-latex.lua.
function Image(el)
  if el.src:sub(1, 1) == "/" and el.src:sub(1, 2) ~= "//" then
    el.src = el.src:sub(2)
  end
  return el
end
