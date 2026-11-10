local _, AUI = ...

-- Original hub loops. Quest identities and level gates still need a live pass.
function AUI.AddZephrasGuides(routes, facts)
    local function add(faction, branch)
        local hubs = {}
        local function hub(name, minimum, maximum, loops, extras)
            local quests, ordered = {}, {}
            local function record(row)
                local id = row[1]
                facts[tostring(id)] = {title = row[2], level = row[3], min = row[4]}
                quests[#quests + 1] = id
                return id
            end
            for _, loop in ipairs(loops) do
                local group = {note = loop[1], quests = {}}
                for index = 2, #loop do
                    group.quests[#group.quests + 1] = record(loop[index])
                end
                ordered[#ordered + 1] = group
            end
            local optional = {}
            for _, row in ipairs(extras or {}) do optional[#optional + 1] = record(row) end
            hubs[#hubs + 1] = {
                name = name, min = minimum, max = maximum, quests = quests, loops = ordered,
                optional = optional,
                note = "Work through these quest groups in order. Check the quest giver if RUI cannot confirm a pickup.",
            }
        end

        hub("Thendal Village and Grove", 1, 5, {
            {"Start by finding Rorian in Thendal Village.", {92460, "Coming of Age", 1, 1}},
            {"Take both village jobs before heading into the grove.",
                {92461, "Harmony in Balance", 1, 1}, {92462, "Infestation Investigation", 2, 1}},
            {"Speak to Yala in the grove. Check your trainer while in the village.",
                {92464, "Elemental Unrest", 3, 2}},
            {"Clear the elementals and converts in the grove before reporting back.", {92465, "Agitators", 3, 2}},
            {"Report to Rorian, then follow up with Aetheen.",
                {92469, "Return to Rorian", 4, 3}},
            {"Meet Aetheen before looking for the Ursera.", {92471, "Aetheen of the Gales", 4, 4}},
            {"Finish the Ursera hunt before leaving Thendal Grove.",
                {92470, "Foul Matriarch", 5, 2}},
            {"Take the handoff to Constable Aonda.", {92472, "The Next Step", 5, 3}},
        }, {branch.racial, {92463, "The Cirrusfly Queen", 3, 2},
            {93552, "Harvesting Windstones", 4, 2}, {92473, "Aggressive Encroachment", 4, 3}})
        hub("Shen'dar Highlands", 5, 9, {
            {"Make the introductions in Shen'dar Village.", branch.welcome},
            {"Pick up the village jobs before sweeping the highlands.",
                {92515, "The Problem With Prideclaws", 6, 4}, {92517, "The Criminal Element", 7, 4}},
            {"Follow up on the bandit investigation.", {93036, "Infiltrating the Cult", 8, 5}},
            {"Meet the contact outside Falaath Village.", {92529, "Falaath Village", 8, 5}},
            {"Find out what the cult is doing before returning to Aonda.", {92528, "Among the Faithful", 8, 5}},
            {"Clear the cult's forces and check in at the western watch.",
                {92550, "Havoc in the Highlands", 8, 5}, {93926, "The Western Watch", 8, 5}},
            {"Resolve the watch's request before heading for Valanaar.", {93927, "A Last Request", 8, 5}},
            {"Carry Aonda's report to Valanaar.", branch.valanaar},
        }, {{92516, "Hippogryph Harrassment", 7, 4}, {92553, "Restocking the Larders", 6, 4},
            {93319, "Pilfered Windstones", 7, 4}, {92551, "Stolen Supplies", 8, 5}})
        hub("Valanaar and the Lowlands", 8, 12, branch.valanaarLoops)
        hub("Rohashi Spires and departure", 11, 13, {
            {"Prepare for the assault in Valanaar.", {93065, "Prepare for Battle", 12, 7}},
            {"Join the advance and then enter the sanctum.", {92947, "Making Our Move", 12, 7}},
            {"Continue through the sanctum.", {93958, "The Inner Sanctum", 12, 7}},
            {"Take the portal and confront Lorthuna.", branch.confront},
            {"Return to report the outcome.", branch.fate},
            {"Speak with your faction contact when you are ready to leave.", branch.departure},
            {branch.travel, branch.arrival},
        })
        routes[#routes + 1] = {
            id = "zephras-" .. faction:lower(), name = "Zephras Isle", faction = faction,
            race = "Skyborne", area = 16593, mapID = 2521, min = 1, max = 13, hubs = hubs,
            draft = true,
        }
    end

    local function valanaarLoops(fork)
        local loops = {}
        for _, loop in ipairs(fork) do loops[#loops + 1] = loop end
        local shared = {
            {"Defend the tower before starting the lowland strike.", {93320, "Tower Defense", 11, 6}},
            {"Pick up both strike objectives before fighting through the Lowlands.",
                {92642, "Disrupting Logistics", 11, 6}, {92645, "Breaking the Breaker", 11, 6}},
            {"Report back in Valanaar.", {92880, "Return to Valanaar", 11, 6}},
            {"Speak with the High Elder for your next lead.", {92881, "The High Elder's Request", 11, 6}},
            {"Find the turncoat outside Valanaar.", {92643, "The Turncoat", 11, 6}},
            {"Carry the crystal back to Valanaar.", {92644, "Unfortunate News", 11, 6}},
            {"Find out what the cult is planning.", {94568, "The Cult's True Plans", 11, 6}},
            {"Speak with Valennia and follow her instructions.", {92640, "Desperate Times", 11, 6}},
        }
        for _, loop in ipairs(shared) do loops[#loops + 1] = loop end
        return loops
    end

    add("Alliance", {
        racial = {92597, "Reading the Ley Lines", 4, 2},
        welcome = {93461, "Welcome to Shen'dar Village", 6, 4},
        valanaar = {92701, "To Valanaar", 9, 6},
        valanaarLoops = valanaarLoops({
            {"Meet the Supreme Magister.", {92699, "The Supreme Magister", 9, 4}},
            {"Follow the scholar investigation one lead at a time.", {92727, "The Missing Scholar", 10, 4}},
            {"Follow the second lead.", {92849, "The Missing Scholar", 10, 4}},
            {"Finish the scholar investigation.", {92850, "The Missing Scholar", 10, 4}},
            {"Follow up on Fillion's mission.", {99260, "Fillion's Mission", 10, 5}},
            {"Complete Catching Wind before taking the next assignment.", {92840, "Catching Wind", 11, 5}},
            {"Take the assignment that leads to the tower.", {92860, "In Service of Zephras", 12, 6}},
        }),
        confront = {93835, "Confront Lorthuna", 12, 7},
        fate = {94369, "The Fate of Zephras", 12, 7},
        departure = {93089, "What Comes Next", 13, 7},
        arrival = {94946, "The Magical City of Dalaran", 13, 7},
        travel = "Board the skycutter to Dalaran, then turn in the arrival quest.",
    })
    add("Horde", {
        racial = {92598, "The Gift of Skysight", 4, 2},
        welcome = {92514, "Welcome to Shen'dar Village", 6, 4},
        valanaar = {92579, "To Valanaar", 8, 6},
        valanaarLoops = valanaarLoops({
            {"Meet the Grand Skyseer.", {92700, "The Grand Skyseer", 9, 4}},
            {"Start investigating the construct.", {93735, "The Broken Construct", 9, 4}},
            {"Follow the construct's second lead.", {93737, "The Broken Construct", 9, 4}},
            {"Finish the construct investigation.", {93738, "The Broken Construct", 9, 4}},
            {"Follow up on the construct investigation.", {93746, "A Firm Response", 9, 4}},
            {"Take the assignment that leads to the tower.", {92871, "In Service of Zephras", 11, 6}},
        }),
        confront = {92646, "Confront Lorthuna", 12, 7},
        fate = {93836, "The Fate of Zephras", 12, 7},
        departure = {93090, "What Comes Next", 13, 7},
        arrival = {95349, "The Earthen Ring", 13, 7},
        travel = "Board the skycutter to Mulgore, then turn in the arrival quest.",
    })
end
