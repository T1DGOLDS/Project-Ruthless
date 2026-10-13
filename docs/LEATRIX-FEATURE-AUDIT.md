# Leatrix feature inventory — 2026-10-11

User requested relevant Plus and Maps functionality within RUI settings. This is a read-only inventory of the installed Forever versions, not an implementation or compatibility claim. Pending user choice: independent replacement versus controls for installed addons. Do not change Leatrix saved variables behind its local runtime state or copy its implementation without checking the applicable license. RUI already owns bag layout, chat dock, unit frames, quest markers and map placement; those need a single owner rather than competing hooks.

## Leatrix Plus 1.60.12

144 checkbox controls found, including sub-options. Buttons, sliders and custom dialogs require their own audit.

| Setting | Control | Reload declared |
| --- | --- | --- |
| Restrict to friends | InviteFriendsOnly | No |
| Airships | MuteAirships | No |
| Horsesteps | MuteHorsesteps | No |
| Mechsteps | MuteMechSteps | No |
| Mechstriders | MuteStriders | No |
| Zeppelins | MuteZeppelins | No |
| Chimes | MuteChimes | No |
| Fizzle | MuteFizzle | No |
| Interface | MuteInterface | No |
| Login | MuteLogin | No |
| Ready | MuteReady | No |
| Trains | MuteTrains | No |
| Vaults | MuteVaults | No |
| Piccolo | MutePiccolo | No |
| Yawns | MuteYawns | No |
| Links go directly to the comments section | WowheadLinkComments | No |
| Show item buttons | DressupItemButtons | No |
| Show animation slider | DressupAnimControl | No |
| Increase zoom out distance | DressupMoreZoomOut | Yes |
| Show animation slider | DressupTransmogAnim | No |
| Accept regular quests automatically | AutoQuestRegular | No |
| Accept daily quests automatically | AutoQuestDaily | No |
| Accept weekly quests automatically | AutoQuestWeekly | No |
| Turn-in completed quests automatically | AutoQuestCompleted | No |
| Require override key for quest automation | AutoQuestShift | No |
| Show vendor summary in chat | AutoSellShowSummary | No |
| Exclude all unbound grey gear | AutoSellNoGreyGear | No |
| Repair using guild funds if available | AutoRepairGuildFunds | No |
| Show repair summary in chat | AutoRepairShowSummary | No |
| Show player frame in class color | ClassColPlayer | No |
| Show target frame and focus frame in class color | ClassColTarget | No |
| Hide addon buttons | HideMiniAddonButtons | No |
| Minimap button bag | MinimapButtonBag | Yes |
| Square minimap | SquareMinimap | Yes |
| Hide addon menu | HideMiniAddonMenu | Yes |
| Unclamp minimap cluster | UnclampMinimap | Yes |
| Show background | FlightBarBackground | No |
| Show destination | FlightBarDestination | No |
| Fill instead of drain | FlightBarFillBar | No |
| Speak the remaining time | FlightBarSpeech | No |
| Help contribute flight times | FlightBarContribute | No |
| Hallow's End: Hallowed Wand | TransHallowed | No |
| Hallow's End: Weighted Jack-o'-Lantern | TransLantern | No |
| Noblegarden: Noblegarden Bunny | TransNobleBunny | No |
| Pilgrim's Bounty: Turkey Shooter | TransTurkey | No |
| Noggenfogger Elixir | TransNoggenfogger | No |
| Devotion Aura | CancelDevotion | No |
| Stealth | CancelStealth | No |
| Intellect | CancelIntel | No |
| Aspect of the Monkey | CancelMonkey | No |
| Block spell links during combat | BlockSpellLinks | No |
| Block drunken spam | BlockDrunkenSpam | No |
| Block duel spam | BlockDuelSpam | No |
| Exclude combat resurrection | AutoResNoCombat | No |
| Exclude afterlife resurrection | AutoResNoAfterlife | No |
| Exclude Alterac Valley | AutoReleaseNoAlterac | No |
| Exclude Stormwind (debug) | AutoReleaseNoStormwind | No |
| Show voice chat buttons | ShowVoiceButtons | No |
| Show chat menu button | ShowChatMenuButton | No |
| Show guild ranks for your guild | TipShowRank | No |
| Show guild ranks for other guilds | TipShowOtherRank | No |
| Show the unit's target | TipShowTarget | No |
| Color the backdrops based on faction | TipBackSimple | No |
| Hide the health bar | TipNoHealthBar | Yes |
| Hide tooltips for world units during combat | TipHideInCombat | No |
| Show tooltips with shift key | TipHideShiftOverride | No |
| Automate quests | AutomateQuests | No |
| Automate gossip | AutomateGossip | No |
| Accept summon | AutoAcceptSummon | No |
| Accept resurrection | AutoAcceptRes | No |
| Release in PvP | AutoReleasePvP | No |
| Sell junk automatically | AutoSellJunk | Yes |
| Repair automatically | AutoRepairGear | No |
| Block duels | NoDuelRequests | No |
| Block party invites | NoPartyInvites | No |
| Block requested invites | NoRequestedInvites | No |
| Block friend requests | NoFriendRequests | No |
| Block shared quests | NoSharedQuests | No |
| Party from friends | AcceptPartyFriends | No |
| Invite from whispers | InviteFromWhisper | No |
| Guild | FriendlyGuild | No |
| Communities | FriendlyCommunities | No |
| Use easy resizing | UseEasyChatResizing | Yes |
| Hide the combat log | NoCombatLogTab | Yes |
| Hide chat buttons | NoChatButtons | Yes |
| Hide social button | NoSocialButton | Yes |
| Unclamp chat frame | UnclampChat | Yes |
| Move editbox to top | MoveChatEditBoxToTop | Yes |
| Set chat font size | SetChatFontSize | Yes |
| Disable sticky chat | NoStickyChat | Yes |
| Use arrow keys in chat | UseArrowKeysInChat | Yes |
| Disable chat fade | NoChatFade | Yes |
| Universal group color | UnivGroupColor | No |
| Recent chat window | RecentChatWindow | Yes |
| Filter chat messages | FilterChatMessages | Yes |
| Restore chat messages | RestoreChatMessages | Yes |
| Hide error messages | HideErrorMessages | Yes |
| Hide portrait numbers | NoHitIndicators | Yes |
| Hide zone text | HideZoneText | Yes |
| Hide keybind text | HideKeybindText | Yes |
| Hide macro text | HideMacroText | Yes |
| Resize quest text | QuestFontChange | Yes |
| Enhance minimap | MinimapModder | Yes |
| Enhance tooltip | TipModEnable | Yes |
| Enhance dressup | EnhanceDressup | Yes |
| Enhance flight map | EnhanceFlightMap | Yes |
| Show volume slider | ShowVolume | Yes |
| Show durability status | DurabilityStatus | Yes |
| Show raid button | ShowRaidToggle | Yes |
| Show train all button | ShowTrainAllButton | Yes |
| Show borders | ShowBorders | Yes |
| Show player chain | ShowPlayerChain | Yes |
| Show ready timer | ShowReadyTimer | Yes |
| Show Wowhead links | ShowWowheadLinks | Yes |
| Manage widget top | ManageWidgetTop | Yes |
| Class colored frames | ClassColFrames | Yes |
| Hide alerts | NoAlerts | Yes |
| Hide clean-up buttons | HideCleanupBtns | Yes |
| Hide boss banner | HideBossBanner | Yes |
| Hide event toasts | HideEventToasts | Yes |
| Hide stance bar | NoClassBar | Yes |
| Hide rested sleep | NoRestedSleep | Yes |
| Disable drunken haze | NoDrunkenHaze | No |
| Disable screen effects | NoScreenEffects | No |
| Set weather density | SetWeatherDensity | No |
| Max camera zoom | MaxCameraZoom | No |
| Silence rested emotes | NoRestedEmotes | Yes |
| Keep audio synced | KeepAudioSynced | Yes |
| Mute game sounds | MuteGameSounds | No |
| Mute mount sounds | MuteMountSounds | No |
| Mute custom sounds | MuteCustomSounds | No |
| Disable bag automation | NoBagAutomation | Yes |
| Remove raid restrictions | NoRaidRestrictions | No |
| Disable loot warnings | NoConfirmLoot | No |
| Faster auto loot | FasterLooting | Yes |
| Faster movie skip | FasterMovieSkip | Yes |
| Combat plates | CombatPlates | Yes |
| Easy item destroy | EasyItemDestroy | Yes |
| Remove transforms | NoTransforms | No |
| Show flight times | ShowFlightTimes | Yes |
| Show minimap button | ShowMinimapIcon | No |
| Use English language | UseEnglishLanguage | Yes |
| Set edit mode layout | SetEditModeLayout | No |
| Simple addon listing | SimpleAddonListing | Yes |

## Leatrix Maps 1.60.14

23 checkbox controls found, including sub-options. Buttons, sliders and custom dialogs require their own audit.

| Setting | Control | Reload declared |
| --- | --- | --- |
| Unlock battlefield map | UnlockBattlefield | No |
| Center map on player | BattleCenterOnPlayer | No |
| Show background | CoordsBackground | No |
| Allow frame movement | EnableMovement | No |
| Show minimum fishing skill levels | ShowFishingLevels | No |
| Show dungeons and raids | ShowDungeonIcons | No |
| Show travel points for same faction | ShowTravelPoints | No |
| Show travel points for opposing faction | ShowTravelOpposing | No |
| Show spirit healers | ShowSpiritHealers | No |
| Show zone crossings | ShowZoneCrossings | No |
| Tint unexplored areas | RevTint | No |
| Unlock map frame | UnlockMap | Yes |
| Scale the map | ScaleWorldMap | Yes |
| Show unexplored areas | RevealMap | Yes |
| Show points of interest | ShowPointsOfInterest | Yes |
| Show zone levels | ShowZoneLevels | Yes |
| Show coordinates | ShowCoords | Yes |
| Hide town and city icons | HideTownCity | Yes |
| Enhance battlefield map | EnhanceBattleMap | Yes |
| Disable map fade | NoMapFade | No |
| Hide filter reset button | NoFilterResetBtn | Yes |
| Show minimap button | ShowMinimapIcon | No |
| Use English language | UseEnglishLanguage | Yes |
