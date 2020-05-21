iCustomNamesDB = iCustomNamesDB or {}
iCN = {}
local icnFrame
local function functionParseImports(str)
	str = {strsplit(";",str)}
	local i = 0
	for k,v in pairs(str) do
		local from, to = strsplit(":",v)
		if from and to and from ~= to then -- nil check
			if not iCustomNamesDB[from] then
				iCustomNamesDB[from] = to
				print("New:", from, to)
				i = i + 1
			end
		end
	end
	print("iCustomNames: " .. i .. " names added to the list.")
end
local function showImportBox()
	if not icnFrame then
		icnFrame = CreateFrame('EditBox', 'iCNCopyFrame', UIParent)
		icnFrame:SetBackdrop({
				bgFile = "Interface\\Buttons\\WHITE8x8",
				edgeFile = "Interface\\Buttons\\WHITE8x8",
				edgeSize = 1,
				insets = {
					left = -1,
					right = -1,
					top = -1,
					bottom = -1,
				},
			});
		icnFrame:SetBackdropColor(0,0,0,0.2)
		icnFrame:SetBackdropBorderColor(1,1,1,1)
		icnFrame:SetScript('OnEnterPressed', function()
			icnFrame:ClearFocus()
			functionParseImports(icnFrame:GetText())
			icnFrame:SetText('')
			icnFrame:Hide()
		end)
		icnFrame:SetAutoFocus(true)
		icnFrame:SetWidth(400)
		icnFrame:SetHeight(21)
		icnFrame:SetTextInsets(2, 2, 1, 0)
		--iEET.copyFrame:SetMultiLine(true)
		icnFrame:SetPoint('CENTER', UIParent, 'CENTER', 0,0)
		icnFrame:SetFrameStrata('DIALOG')
		icnFrame:Show()
		icnFrame:SetFont(NumberFont_Shadow_Small:GetFont(), 14, 'OUTLINE')
	else
		if icnFrame:IsShown() then
			icnFrame:Hide()
		else
			icnFrame:Show()
		end
	end
end

function iCN_GetName(name)
	if iCustomNamesDB[name] then
		return iCustomNamesDB[name]
	else
		return name
	end
end


--ElvUI-----
if ElvUF and ElvUF.Tags then
	ElvUF.Tags.Events['icn'] = 'UNIT_NAME_UPDATE'
	ElvUF.Tags.Methods['icn'] = function(unit)
		local name = UnitName(unit)
		if iCustomNamesDB[name] then
			return iCustomNamesDB[name]
		else
			return name or ''
		end
	end
end

local addon = CreateFrame('Frame')
addon:SetScript("OnEvent", function(self, event, ...)
	self[event](self, ...)
end)
--[[
function CompactUnitFrame_UpdateName(frame)
	if ( not ShouldShowName(frame) ) then
		frame.name:Hide();
	else
		local name = GetUnitName(frame.unit, true);
		if ( C_Commentator.IsSpectating() and name ) then
			local overrideName = C_Commentator.GetPlayerOverrideName(name);
			if overrideName then
				name = overrideName;
			end
		end

		frame.name:SetText(name);

		if ( CompactUnitFrame_IsTapDenied(frame) ) then
			-- Use grey if not a player and can't get tap on unit
			frame.name:SetVertexColor(0.5, 0.5, 0.5);
		elseif ( frame.optionTable.colorNameBySelection ) then
			if ( frame.optionTable.considerSelectionInCombatAsHostile and CompactUnitFrame_IsOnThreatListWithPlayer(frame.displayedUnit) ) then
				frame.name:SetVertexColor(1.0, 0.0, 0.0);
			else
				frame.name:SetVertexColor(UnitSelectionColor(frame.unit, frame.optionTable.colorNameWithExtendedColors));
			end
		end

		frame.name:Show();
	end
end




if iCustomNamesConfig.Blizzard then
	hooksecurefunc("CompactUnitFrame_UpdateName", function(f)
		if f.unit and f.unit:match("raid%d$") then
			print("true",f.unit)
		else
			print("false", f.unit)
		end
	end)
end
--]]
addon:RegisterEvent('ADDON_LOADED')
local raidUnits = {}

function addon:ADDON_LOADED(addonName)
	if addonName == 'VuhDo' then -- VuhDo
		iCN:SetupVuhdo()
	elseif addonName == "BigWigs_Plugins" then
		iCN:SetupBigWigs()
	end
end

--VuhDo------
do 
	local hookedFrames = {}
	function iCN:SetupVuhdo()
		hooksecurefunc('VUHDO_getBarText', function(aBar)
			local bar = aBar:GetName() .. 'TxPnlUnN'
			if bar then
				if not hookedFrames[bar] then
					hookedFrames[bar] = true
					hooksecurefunc(_G[bar], 'SetText', function(self,txt)
						if txt then
							local name = txt:match('%w+$')
							if name then
								local preStr = txt:gsub(name, '')
								self:SetFormattedText('%s%s',preStr,iCN_GetName(name))
							end
						end
					end)
				end
			end
		end)
 	end
end
--BigWigs-----
do
	local formats = {
		["%s: %s"] = "%s: (%s)",
		["%s on %s"] = "%s on (%s)",
		["%dx %s on %s"] = "%dx %s on (%s)",
	}
	local function parseText(txt)
		if not txt then return end
		return txt:gsub("(|cff%x%x%x%x%x%x)(%a-)(%*?|r)",function(s,name,e)
			return s..iCN_GetName(name)..e
		end)
	end
	function iCN:SetupBigWigs()
		local p = BigWigs:GetPlugin("Messages")
		local oldP = p.BigWigs_Message
		p.BigWigs_Message = function(self, event, module, key, text, ...)
			oldP(self, event, module, key, parseText(text), ...)
		end
	end
end

SLASH_ICUSTOMNAMES1 = "/icn"
SlashCmdList["ICUSTOMNAMES"] = function(msg)
	if string.find(string.lower(msg), "add (.-) to (.-)") then
		local _, _, type, from, to = string.find(msg, "(.-) (.*) to (.*)")
		iCustomNamesDB[from] = to
		print("Added: " .. from .. " -> " .. to);
	elseif string.find(string.lower(msg), "del (.-)") then
		local _, _, type, from = string.find(msg, "(.-) (.*)")
		if iCustomNamesDB[from] then
			local to = iCustomNamesDB[from]
			iCustomNamesDB[from] = nil
			print("Deleted: " .. from .. " -> " .. to);
		end
	elseif msg == "list" or msg == "l" then
		for k,v in pairs(iCustomNamesDB) do
			print(k .. " -> " .. v);
		end
	elseif msg == "import" or msg == "i" then
		showImportBox()
	else
		print("iCustomNames example usage:\rAdding a new name: /icn add Kultziliini to Ironi\rDeleting old name: /icn del Kultziliini\rListing every name: /icn (l)ist\rImport: /icn (i)mport")
	end
	if GridCustomNamesUpdate then
		GridCustomNamesUpdate()
	end
end
