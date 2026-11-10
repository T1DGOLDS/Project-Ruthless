-- Historical regression fixture only; not the current development reference.
-- Gethe/wow-ui-source forever a84e2b1b41d3d4137127c07e4da448aa3251d6f1, Blizzard_UIPanels_Game/Mainline/ContainerFrame.lua
function ContainerFrameItemButtonMixin:Initialize(bag, slot)
	self:SetBagID(bag);
	self:SetID(slot);
	self:UpdateExtended();

	-- Potentially temporary, item slots don't have a background, so when they're used in a combined inventory setup
	-- they need to make their own.
	local isCombined = self:GetParent():IsCombinedBagContainer();
	if isCombined and not self.ItemSlotBackground then
		self.ItemSlotBackground = self:CreateTexture(nil, "BACKGROUND", "ItemSlotBackgroundCombinedBagsTemplate", -6);
		self.ItemSlotBackground:SetAllPoints(self);
	end

	if self.ItemSlotBackground then
		self.ItemSlotBackground:SetShown(isCombined);
	end

	self:Show();
end

