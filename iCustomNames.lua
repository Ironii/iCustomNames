iCustomNamesDB = iCustomNamesDB or {}
local iCN = {}
local icnFrame
local function functionParseImports(str)
	str = {strsplit(";",str)}
	local i = 0
	for k,v in pairs(str) do
		local from, to = strsplit(":",v)
		if from and to then -- nil check
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
		icnFrame = CreateFrame('EditBox', 'iCNCopyFrame', UIParent, BackdropTemplateMixin and "BackdropTemplate")
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
	if not name then return end
	local ln = LiquidAPI and LiquidAPI:GetName(name)
	if ln and ln ~= name then
		return ln, true
	elseif iCustomNamesDB[name] then
		return iCustomNamesDB[name], true
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
if ElvUF and ElvUF.Tags then
	ElvUF.Tags.Events['icn-len5'] = 'UNIT_NAME_UPDATE'
	ElvUF.Tags.Methods['icn-len5'] = function(unit)
		local name = UnitName(unit)
		if iCustomNamesDB[name] then
			return iCustomNamesDB[name]:sub(1,5)
		else
			return name:sub(1,5) or ''
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
do
	local spairs, tinsert, sformat = string.format, table.insert, string.format
	local function spairs(t, order)
		-- collect the keys
		local keys = {}
		for k in pairs(t) do keys[#keys+1] = k end
	
		-- if order function given, sort by it by passing the table and keys a, b,
		-- otherwise just sort the keys
		if order then
				table.sort(keys, function(a,b) return order(t, a, b) end)
		else
				table.sort(keys)
		end
	
		-- return the iterator function
		local i = 0
		return function()
				i = i + 1
				if keys[i] then
						return keys[i], t[keys[i]]
				end
		end
	end
	local backdrop = {
		bgFile = 'Interface\\Buttons\\WHITE8x8',
		edgeFile = 'Interface\\Buttons\\WHITE8x8',
		edgeSize = 1,
		insets = {
			left = 0,
			right = 0,
			top = 0,
			bottom = 0,
		}
	}
	local deleteFrame
	local createdLines = {}
	local function getLine(i, mf)
		if not i then return end
		if createdLines[i] then
			return createdLines[i]
		end
		local f = CreateFrame("frame", nil, mf, "BackdropTemplate")
		f:SetSize(582,20)
		f:SetBackdrop(backdrop)
		f:SetBackdropColor(1,1,1,0)
		f:SetBackdropBorderColor(0,0,0,1)
		if i == 1 then
			f:SetPoint("topright", mf, "topright", -3, -3)
		else
			f:SetPoint("topright", createdLines[i-1], "bottomright", 0, -3)
		end
		f.txt = f:CreateFontString()
		f.txt:SetFont(STANDARD_TEXT_FONT, 10, 'OUTLINE')
		f.txt:SetPoint('LEFT', f, 'LEFT', 3, 0)
		f.txt:SetJustifyH("left")
		f.delete = CreateFrame("button", nil, f, "UIPanelButtonTemplate")
		f.delete:SetSize(80, 16)
		f.delete:SetPoint("right", f, "right", -3, 0)
		f.delete:SetText("Delete")
		createdLines[i] = f
		return createdLines[i]
	end
	local function refreshLines(mf)
		local lineCount = 1
		local tempNames = {}
		for k,v in pairs(iCustomNamesDB) do
			if not tempNames[v] then
				tempNames[v] = {}
			end
			tinsert(tempNames[v], k)
		end
		for k,v in spairs(tempNames) do
			local _f = getLine(lineCount, mf.scrollStuff.content)
			_f:SetBackdropColor(.3,.3,.3,.1)
			_f.delete:SetScript("OnClick", function()
				for k,v in pairs(v) do
					iCustomNamesDB[v] = nil
				end
				refreshLines(mf)
			end)
			_f:SetWidth(582)
			_f.txt:SetText(sformat("%s, Char count: %s", k, #v))
			lineCount = lineCount + 1
		end
		for j = lineCount, #createdLines do
			createdLines[j]:Hide()
		end
		local totalHeight = (lineCount-1)*23+3
		mf.scrollStuff.content:SetHeight(totalHeight)
		mf.scrollStuff.slider:SetMinMaxValues(0, totalHeight-680)
	end
	function iCN:showDeleteOptions()
		if not deleteFrame then
			local backdrop = {
				bgFile = 'Interface\\Buttons\\WHITE8x8',
				edgeFile = 'Interface\\Buttons\\WHITE8x8',
				edgeSize = 1,
				insets = {
					left = 0,
					right = 0,
					top = 0,
					bottom = 0,
				}
			}
			deleteFrame = CreateFrame("frame", nil, UIParent, "BackdropTemplate")
			deleteFrame:SetSize(600, 800)
			deleteFrame:SetFrameStrata("high")
			deleteFrame:SetBackdrop(backdrop)
			deleteFrame:SetBackdropColor(0.1,0.1,0.1,0.8)
			deleteFrame:SetBackdropBorderColor(0,0,0,1)
			deleteFrame:SetPoint("top", UIParent, "top", 0, -50)
			
			deleteFrame.scrollStuff = CreateFrame('ScrollFrame', nil, deleteFrame, "BackdropTemplate")
			local f = deleteFrame.scrollStuff
			f:SetBackdrop(backdrop)
			f:SetBackdropColor(0,0,0,0)
			f:SetBackdropBorderColor(0,0,0,1)
			f:EnableMouseWheel(true)
			f:SetPoint("topleft", deleteFrame, "topleft", 3, -75)
			f:SetSize(588, 680)
			f.content = CreateFrame('frame', nil, f)
			f.content:SetWidth(588)
			f.content:SetHeight(1000)
			f.content:SetPoint('topleft', f, 'topleft', 0,0)
			f:SetScrollChild(f.content)
			--Scroll
			f.slider = CreateFrame('Slider', nil, f, "BackdropTemplate")
			f.slider:SetWidth(4)
			f.slider:SetThumbTexture('Interface\\AddOns\\iEncounterEventTracker\\media\\thumb')
			f.slider:SetBackdrop(backdrop)
			f.slider:SetBackdropColor(0.1,0.1,0.1,0.9)
			f.slider:SetBackdropBorderColor(0,0,0,1)
			f.slider:SetPoint("topleft", f, "topright", 2, 0)
			f.slider:SetPoint("bottomleft", f, "bottomright", 2, 0)
			f.slider:SetMinMaxValues(0, 1000)
			f.slider:SetValue(0)
			f.slider:EnableMouseWheel(true)
			f.slider:SetScript('OnValueChanged', function(self, value)
				f:SetVerticalScroll(value)
			end)
			local contentScrollFunc = function(self, delta)
				local changeVal = IsShiftKeyDown() and 200 or 20
				if delta == -1 then --down

					local value = f.slider:GetValue()+changeVal
					local min, max = f.slider:GetMinMaxValues()
					value = math.min(value, max)
					f.slider:SetValue(value)
				else -- up
					local value = f.slider:GetValue()-changeVal
					value = max(0, value)
					f.slider:SetValue(value)
				end
			end
			f.resizeContent = function(height)
				height = math.ceil(height)
				f.content:SetHeight(math.floor(height))
				f.slider:SetMinMaxValues(0, math.max(height-f.slider:GetHeight(),0))
			end
			f:SetScript('OnMouseWheel', contentScrollFunc)
			f.slider:SetScript('OnMouseWheel', contentScrollFunc)
			local closeButton = CreateFrame("button", nil, deleteFrame, "UIPanelButtonTemplate")
			closeButton:SetSize(100, 20)
			closeButton:SetPoint("bottom", deleteFrame, "bottom", 0, 5)
			closeButton:SetText("Close")
			closeButton:SetScript("OnClick", function() deleteFrame:Hide() end)
			refreshLines(deleteFrame)
			deleteFrame:Show()
		elseif deleteFrame:IsShown() then
			deleteFrame:Hide()
		else
			refreshLines(deleteFrame)
			deleteFrame:Show()
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
	elseif msg == "deloptions" or msg == "do" then
		iCN:showDeleteOptions()
	else
		print("iCustomNames example usage:\rAdding a new name: /icn add Kultziliini to Ironi\rDeleting old name: /icn del Kultziliini\rListing every name: /icn (l)ist\rImport: /icn (i)mport")
	end
	if GridCustomNamesUpdate then
		GridCustomNamesUpdate()
	end
end