local _,AUI=...
local loader={}
AUI:RegisterModule("Menu",loader)
function loader:Show(tab)
    local ok,reason=C_AddOns.LoadAddOn("ProjectRuthless_Options")
    local menu=AUI.modules.Menu
    if ok and menu~=self then menu:Show(tab);return end
    AUI:Print("Settings could not load. Enable/install RUI Options alongside RUI. "..tostring(reason or "Missing options module."))
end
