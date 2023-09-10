LiAutoRepairVersionNum = 12
AddonMsgPrefix = "LiARVersion"

C_ChatInfo.RegisterAddonMessagePrefix(AddonMsgPrefix)
UpdateNotificationDisplayed = false
LiAutoRepair = false

InventorySlots = {
	"HeadSlot",
	"ShoulderSlot",
	"ChestSlot",
	"WristSlot",
	"HandsSlot",
	"WaistSlot",
	"LegsSlot",
	"FeetSlot",
	"MainHandSlot",
	"SecondaryHandSlot"
}

function LiARGetDurability()
	DCur, DMax = 0, 0
	for _, v in pairs(InventorySlots) do
		iCur, iMax = GetInventoryItemDurability(GetInventorySlotInfo(v));
		iCur, iMax = (iCur or 0), (iMax or 0)
		DCur = DCur + iCur
		DMax = DMax + iMax
	end

	return DCur, DMax
end

function SendAddonVerMessages()
	C_ChatInfo.SendAddonMessage(AddonMsgPrefix, LiAutoRepairVersionNum, "GUILD")
	C_ChatInfo.SendAddonMessage(AddonMsgPrefix, LiAutoRepairVersionNum, "PARTY")
	C_ChatInfo.SendAddonMessage(AddonMsgPrefix, LiAutoRepairVersionNum, "RAID")
end

function LiAutoRepairInit()
	FrameLiAutoRepair:SetScript("Onevent", LiAutoRepairEvent)
	FrameLiAutoRepair:RegisterEvent("MERCHANT_SHOW")
	FrameLiAutoRepair:RegisterEvent("CHAT_MSG_ADDON")
	FrameLiAutoRepair:RegisterEvent("UPDATE_INVENTORY_DURABILITY")
	DEFAULT_CHAT_FRAME:AddMessage("[Li-AutoRepair] Version "..tostring(LiAutoRepairVersionNum).." loaded.")
	SendAddonVerMessages()
end

function round(number, decimals)
	return (("%%.%df"):format(decimals)):format(number)
end

-- Most of this would not be neccecary if RepairAllItems() returned true/false for success/fail,
-- but instead, we have to rely on a timed cycle and a hook to UPDATE_INVENTORY_DURABILITY.
function LiAR_OnUpdate(self, elapsed)
	if (LiAutoRepair == true) then

		if (Total_GR >= 0.25) and (Total < 1) then
			if ((IsInGuild() == true) and (CanGuildBankRepair() == true) and (RepairUsingGuild == true)) then
				if (GRepairAttempted == false) then
					RepairAllItems(true)
					Total_GR = 0
					GRepairAttempted = true
				end
			else
				RepairUsingGuild = false
			end
		end

		if (((Total_PR >= 0.25) and (Total > 2)) or (RepairUsingGuild == false)) then
			if (RepairAllCost <= GetMoney()) then
				if (PRepairAttempted == false) then
					RepairAllItems(false)
					Total_PR = 0
					PRepairAttempted = true
				end
			else
				RepairUsingPersonal = false
			end
		end

		if ((RepairUsingGuild == false) and (RepairUsingPersonal == false)) then
			LiAutoRepair = false
			DEFAULT_CHAT_FRAME:AddMessage("[Li-AutoRepair] Could not repair your gear!")
		end

		Total_GR = Total_GR + elapsed
		Total_PR = Total_PR + elapsed
		Total = Total + elapsed
	end
end
CreateFrame("frame"):SetScript("OnUpdate", LiAR_OnUpdate)

function LiAutoRepairEvent(self, event, prefix, message, chatType, sender)
	if ((event == "MERCHANT_SHOW") and (CanMerchantRepair() == true)) then
		RepairAllCost, CanRepair = 0, false
		RepairAllCost, CanRepair = GetRepairAllCost()
		if ((CanRepair == true) and (RepairAllCost > 0)) then
			Start_Dur, Start_MaxDur = LiARGetDurability()
			if (Start_Dur < Start_MaxDur) then
				Total = 0
				Total_GR = 0
				Total_PR = 0
				RepairUsingGuild = true
				RepairUsingPersonal = true
				GRepairAttempted = false
				PRepairAttempted = false
				LiAutoRepair = true
			end
		end
	end

	if (event == "UPDATE_INVENTORY_DURABILITY") then
		End_Dur, End_MaxDur = LiARGetDurability()
		if (LiAutoRepair == true) then
			if ((End_Dur == End_MaxDur) and (Start_Dur < End_Dur)) then
				LiAutoRepair = false
				if (((Total < 2) and (RepairUsingGuild == true)) or (RepairUsingPersonal == false)) then
					FundType = " [Guild] funds."
				elseif (((Total > 2) and (RepairUsingPersonal == true)) or (RepairUsingGuild == false)) then
					FundType = " [Personal] funds."
				else
					FundType = "."
				end
				DEFAULT_CHAT_FRAME:AddMessage("[Li-AutoRepair] Repaired all equipment from "..round((Start_Dur/Start_MaxDur)*100, 1).."% durability.")
				DEFAULT_CHAT_FRAME:AddMessage("[Li-AutoRepair] Costing "..GetCoinTextureString(RepairAllCost)..FundType)
			end
		end
	end

	if (event == "CHAT_MSG_ADDON") and (AddonMsgPrefix == prefix) then
		if (LiAutoRepairVersionNum < tonumber(message)) and (UpdateNotificationDisplayed == false) then
			DEFAULT_CHAT_FRAME:AddMessage("[Li-AutoRepair] A newer version of LiAutoRepair is avalible, you should update!")
			UpdateNotificationDisplayed = true
		elseif (LiAutoRepairVersionNum > tonumber(message)) then
			SendAddonVerMessages()
		end
	end
end
