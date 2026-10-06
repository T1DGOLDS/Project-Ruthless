const fs = require('fs');
const path = require('path');
const assert = require('assert');

const root = path.resolve(process.argv[2] || path.join(__dirname, '..'));
const dependencyRoot = process.env.PR_TEST_DEPS || path.join(root, 'node_modules');
const nativeRoot = process.env.PR_WOW_FOREVER_SOURCE;
if (!nativeRoot) {
  throw new Error('Set PR_WOW_FOREVER_SOURCE to the WoW Forever Interface/AddOns source directory.');
}

const parser = require(path.join(dependencyRoot, 'luaparse'));
for (const file of fs.readdirSync(root, { recursive: true }).filter(file => file.endsWith('.lua') && !file.startsWith('tests'))) {
  parser.parse(fs.readFileSync(path.join(root, file), 'utf8'), { luaVersion: '5.1' });
}
console.log('PASS: Lua 5.1 syntax');

function read(relativePath) {
  return fs.readFileSync(path.join(root, relativePath), 'utf8');
}

function native(relativePath) {
  return fs.readFileSync(path.join(nativeRoot, relativePath), 'utf8');
}

function tocFiles(source) {
  return source.split(/\r?\n/)
    .map(line => line.trim())
    .filter(line => line && !line.startsWith('##'));
}

const retailToc = read('ProjectRuthless.toc');
const foreverToc = read('ProjectRuthless_Camelot.toc');
assert.match(foreverToc, /^## Interface: 16001$/m);
assert.match(foreverToc, /^## AllowLoadGameType: camelot$/m);
assert.deepStrictEqual(tocFiles(foreverToc), tocFiles(retailToc), 'Retail and Forever must load the same production files in the same order');
console.log('PASS: Camelot manifest and file order');

const core = read('Core.lua');
assert.match(core, /AUI\.isForever\s*=\s*AUI\.interfaceVersion\s*>=\s*16000\s*and\s*AUI\.interfaceVersion\s*<\s*20000/);
for (const feature of ['Character', 'Talents', 'Achievements']) {
  assert.match(core, new RegExp(`${feature}\\s*=\\s*true`), `${feature} must be protected on Forever`);
}

const simpleEditBoxAPI = native('Blizzard_APIDocumentationGenerated/SimpleEditBoxAPIDocumentation.lua');
const simpleFontStringAPI = native('Blizzard_APIDocumentationGenerated/SimpleFontStringAPIDocumentation.lua');
assert.doesNotMatch(simpleEditBoxAPI, /Name = "GetStringHeight"/, 'Recheck scrolling edit-box measurement: Forever now exposes GetStringHeight directly');
assert.match(simpleFontStringAPI, /Name = "GetStringHeight"/);
assert.doesNotMatch(core, /box:GetStringHeight\(\)/, 'SimpleEditBox cannot measure string height on Forever');
assert.match(core, /measurement:GetStringHeight\(\)/);
console.log('PASS: Forever scrolling edit boxes use the supported FontString measurement API');

const mapQuests = read('Modules/MapQuests.lua');
const menu = read('Modules/Menu.lua');
const questOfferProvider = native('Blizzard_SharedMapDataProviders/QuestOfferDataProvider.lua');
const worldMap = native('Blizzard_WorldMap/Blizzard_WorldMap.lua');
assert.match(worldMap, /AddDataProvider\(CreateFromMixins\(QuestOfferDataProviderMixin\)\)/);
assert.match(questOfferProvider, /QuestOfferDataProviderMixin:Init\("questPOILocalStory"\)/);
assert.match(questOfferProvider, /C_QuestLine\.GetAvailableQuestLines\(mapID\)/);
assert.match(mapQuests, /SetCVar\("questPOILocalStory",enabled and settings\.showLocalStories and "1" or "0"\)/);
assert.match(mapQuests, /Enum\.MinimapTrackingFilter\.TrivialQuests/);
assert.match(mapQuests, /Enum\.MinimapTrackingFilter\.AccountCompletedQuests/);
assert.match(mapQuests, /C_QuestLine\.RequestQuestLinesForMap\(mapID\)/);
assert.match(mapQuests, /WorldMapFrame:RefreshAllDataProviders\(\)/);
assert.doesNotMatch(mapQuests, /AcquirePin\(/, 'MapQuests should preserve Blizzard pin ownership');
assert.match(core, /mapQuests\s*=\s*{[\s\S]*?showLocalStories\s*=\s*true[\s\S]*?showTrivial\s*=\s*true[\s\S]*?showAccountCompleted\s*=\s*false/);
assert.match(menu, /CreateTab\("mapquests", "Map & quests", 6\)/);
console.log('PASS: lightweight quest map uses Forever native offers, filters, and Blizzard-owned pins');

const character = read('Modules/CharacterV2.lua');
const talents = read('Modules/Talents.lua');
const achievements = read('Modules/Achievements.lua');
assert.match(character, /function Character:OnPlayerLogin\(\)\s*\n\s*if not self:IsSupported\(\) then return end/);
assert.match(talents, /function Talents:OnPlayerLogin\(\)\s*\n\s*if not AUI:IsFeatureSupported\("Talents"\) then return end/);
assert.match(achievements, /function Achievements:OnPlayerLogin\(\)\s*\n\s*if not AUI:IsFeatureSupported\("Achievements"\) then return end/);
assert.doesNotMatch(menu, /if AUI\.isForever then[\s\S]*?ToggleCharacter\(/, 'Forever menu must not taint secret values by calling ToggleCharacter');
const unsupportedTalentsBranch = talents.match(/if not AUI:IsFeatureSupported\("Talents"\) then([\s\S]*?)\n\s*end/)[1];
assert.doesNotMatch(unsupportedTalentsBranch, /OpenToClassTalentsTab/, 'Unsupported Forever Talents must stay on the native launch path');
console.log('PASS: Forever leaves unsupported native frames untouched');

const spellbook = read('Modules/Spellbook.lua');
assert.match(spellbook, /function Spellbook:InstallMicroButton\(\)[\s\S]*?if AUI\.isForever then return end/);
assert.match(spellbook, /self\.originalToggleSpellBookFrame=PlayerSpellsUtil\.ToggleSpellBookFrame/);
assert.match(spellbook, /if AUI\.isForever and self\.originalToggleSpellBookFrame then[\s\S]*?PlayerSpellsUtil\.ToggleSpellBookFrame=function/);
assert.match(spellbook, /Spellbook\.originalOpenToSpellBookTabAtSpell\(spellID,\.\.\.\)/);

const spellBookAPI = native('Blizzard_APIDocumentationGenerated/SpellBookDocumentation.lua');
assert.match(spellBookAPI, /Name = "GetSpellBookItemCooldown"[\s\S]*?SecretWhenCooldownsRestricted\s*=\s*true/);
assert.match(spellbook, /local combatRestricted=AUI\.isForever and InCombatLockdown\(\)/);
assert.match(spellbook, /if combatRestricted then button\.cooldown:Clear\(\)/);
assert.match(spellbook, /function Spellbook:GetActionBarState\(spellID\)[\s\S]*?if AUI\.isForever and InCombatLockdown\(\) then return self\.actionBarState\[key\] end/);
assert.match(spellbook, /function Spellbook:PulseActionBarLocations\(spellID\)\s*\n\s*if AUI\.isForever then[\s\S]*?return end/);
assert.match(spellbook, /if not AUI\.isForever and MultiActionBar_ShowAllGrids/);
assert.match(spellbook, /if not AUI\.isForever and MultiActionBar_HideAllGrids/);
assert.match(spellbook, /event == "PLAYER_REGEN_DISABLED" and AUI\.isForever[\s\S]*?Spellbook:Refresh\(\)[\s\S]*?return/);
assert.match(spellbook, /AUI\.isForever and InCombatLockdown\(\) then AUI:Print\("Combat Spellbook is browse-only; use your action bars to cast\."\)/);
console.log('PASS: Forever Spellbook provides a read-only combat view without secret cooldowns or protected action-bar mutations');

assert.match(spellbook, /Label\(details,"MACRO NAME","GameFontNormalSmall"\)/);
assert.match(spellbook, /Label\(editorBackground,"MACRO BODY","GameFontNormalSmall"\)/);
assert.match(spellbook, /TYPING IN NAME/);
assert.match(spellbook, /TYPING IN BODY/);
assert.match(spellbook, /OnEditFocusGained/);
assert.match(spellbook, /local function InstallVisibleCaret\(editBox\)/);
assert.match(spellbook, /caret:SetPoint\("TOPLEFT",editBox,"TOPLEFT",caret\.cursorX\+1,caret\.cursorY\)/);
assert.match(spellbook, /caret\.blinkElapsed>=0\.5/);
assert.match(spellbook, /self\.macroNameCaret=InstallVisibleCaret\(name\); self\.macroBodyCaret=InstallVisibleCaret\(editor\)/);
console.log('PASS: macro name and body expose labels, focus feedback, and explicit blinking carets');

const playerSpellsToc = native('Blizzard_PlayerSpells/Blizzard_PlayerSpells.toc');
assert.match(playerSpellsToc, /\[Game\]\/Blizzard_PlayerSpellsFrame\.lua\s+\[AllowLoadGameType camelot\]/);
assert.match(playerSpellsToc, /\[Game\]\/SpellBook\/Blizzard_SpellBookFrame\.lua\s+\[AllowLoadGameType camelot\]/);
const camelotBindings = native('Blizzard_FrameXML/Bindings_Camelot.xml');
assert.match(camelotBindings, /PlayerSpellsUtil\.ToggleSpellBookFrame\(\)/);
console.log('PASS: Forever Spellbook button and keybind redirect contract');

const achievementToc = native('Blizzard_AchievementUI/Blizzard_AchievementUI.toc');
const allowLine = achievementToc.match(/^## AllowLoadGameType:\s*(.+)$/m);
assert(allowLine && !allowLine[1].split(/\s*,\s*/).includes('camelot'), 'Recheck Achievement support: Blizzard now allows the Camelot game type');

const packageScript = read('tools/package.ps1');
assert.match(packageScript, /ProjectRuthless_Camelot\.toc/);
console.log('PASS: package includes Retail and Forever manifests');
