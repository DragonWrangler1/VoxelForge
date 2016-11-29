-- Boilerplate to support localized strings if intllib mod is installed.
local S, F
if minetest.get_modpath("intllib") then
	S = intllib.Getter()
else
	S = function(s) return s end
end
F = function(f) return minetest.formspec_escape(S(f)) end

doc = {}

-- Some informational variables
-- DO NOT CHANGE THEM AFTERWARDS AT RUNTIME!

-- Version number (follows the SemVer specification 2.0.0)
doc.VERSION = {}
doc.VERSION.MAJOR = 0
doc.VERSION.MINOR = 8
doc.VERSION.PATCH = 0
doc.VERSION.STRING = doc.VERSION.MAJOR.."."..doc.VERSION.MINOR.."."..doc.VERSION.PATCH

-- Formspec information
doc.FORMSPEC = {}
-- Width of formspec
doc.FORMSPEC.WIDTH = 12
doc.FORMSPEC.HEIGHT = 9

--[[ Recommended bounding box coordinates for widgets to be placed in entry pages. Make sure
all entry widgets are completely inside these coordinates to avoid overlapping. ]]
doc.FORMSPEC.ENTRY_START_X = 0
doc.FORMSPEC.ENTRY_START_Y = 0.5
doc.FORMSPEC.ENTRY_END_X = doc.FORMSPEC.WIDTH
doc.FORMSPEC.ENTRY_END_Y = doc.FORMSPEC.HEIGHT - 0.5
doc.FORMSPEC.ENTRY_WIDTH = doc.FORMSPEC.ENTRY_END_X - doc.FORMSPEC.ENTRY_START_X
doc.FORMSPEC.ENTRY_HEIGHT = doc.FORMSPEC.ENTRY_END_Y - doc.FORMSPEC.ENTRY_START_Y

--TODO: Use container formspec element later

-- Internal helper variables
local DOC_INTRO = string.format(S("This is the Documentation System, Version %s."), doc.VERSION.STRING)

local CATEGORYFIELDSIZE = {
	WIDTH = 4,
	HEIGHT = 8,
}

doc.data = {}
doc.data.categories = {}
-- Default order (includes categories of other mods from the Docuentation System modpack)
doc.data.category_order = {"basics", "online", "nodes", "tools", "craftitems"}
doc.data.players = {}

-- Space for additional APIs
doc.sub = {}

-- Status variables
local set_category_order_was_called = false

--[[ Core API functions ]]

-- Add a new category
function doc.new_category(id, def)
	if doc.data.categories[id] == nil and id ~= nil then
		doc.data.categories[id] = {}
		doc.data.categories[id].entries = {}
		doc.data.categories[id].entry_count = 0
		doc.data.categories[id].hidden_count = 0
		doc.data.categories[id].def = def
		doc.data.categories[id].entry_aliases = {}
		-- Determine order position
		local order_id = nil
		for i=1,#doc.data.category_order do
			if doc.data.category_order[i] == id then
				order_id = i
				break
			end
		end
		if order_id == nil then
			table.insert(doc.data.category_order, id)
			doc.data.categories[id].order_position = #doc.data.category_order
		else
			doc.data.categories[id].order_position = order_id
		end
		return true
	else
		return false
	end
end

-- Add a new entry
function doc.new_entry(category_id, entry_id, def)
	local cat = doc.data.categories[category_id]
	if cat ~= nil then
		local hidden = def.hidden or (def.hidden == nil and cat.def.hide_entries_by_default)
		if hidden then
			cat.hidden_count = cat.hidden_count + 1
			def.hidden = hidden
		end
		cat.entry_count = doc.data.categories[category_id].entry_count + 1
		if def.name == nil or def.name == "" then
			minetest.log("warning", "[doc] Nameless entry added. Entry ID: "..entry_id)
		end
		cat.entries[entry_id] = def
		return true
	else
		return false
	end
end

-- Marks a particular entry as viewed by a certain player, which also
-- automatically reveals it
function doc.mark_entry_as_viewed(playername, category_id, entry_id)
	local entry, entry_id = doc.get_entry(category_id, entry_id)
	if doc.data.players[playername].stored_data.viewed[category_id] == nil then
		doc.data.players[playername].stored_data.viewed[category_id] = {}
		doc.data.players[playername].stored_data.viewed_count[category_id] = 0
	end
	if doc.entry_exists(category_id, entry_id) and doc.data.players[playername].stored_data.viewed[category_id][entry_id] ~= true then
		doc.data.players[playername].stored_data.viewed[category_id][entry_id] = true
		doc.data.players[playername].stored_data.viewed_count[category_id] = doc.data.players[playername].stored_data.viewed_count[category_id] + 1
		-- Needed because viewed entries get a different color
		doc.data.players[playername].entry_textlist_needs_updating = true
	end
	doc.mark_entry_as_revealed(playername, category_id, entry_id)
end

-- Marks a particular entry as revealed/unhidden by a certain player
function doc.mark_entry_as_revealed(playername, category_id, entry_id)
	local entry, entry_id = doc.get_entry(category_id, entry_id)
	if doc.data.players[playername].stored_data.revealed[category_id] == nil then
		doc.data.players[playername].stored_data.revealed[category_id] = {}
		doc.data.players[playername].stored_data.revealed_count[category_id] = doc.get_entry_count(category_id) - doc.data.categories[category_id].hidden_count
	end
	if doc.entry_exists(category_id, entry_id) and entry.hidden and doc.data.players[playername].stored_data.revealed[category_id][entry_id] ~= true then
		doc.data.players[playername].stored_data.revealed[category_id][entry_id] = true
		doc.data.players[playername].stored_data.revealed_count[category_id] = doc.data.players[playername].stored_data.revealed_count[category_id] + 1
		-- Needed because a new entry is added to the list of visible entries
		doc.data.players[playername].entry_textlist_needs_updating = true
		if minetest.get_modpath("central_message") ~= nil then
			local cat = doc.data.categories[category_id]
			cmsg.push_message_player(minetest.get_player_by_name(playername), string.format(S("New help entry unlocked: %s > %s"), cat.def.name, entry.name))
		end
		-- To avoid sound spamming, don't play sound more than once per second
		local last_sound = doc.data.players[playername].last_reveal_sound
		if last_sound == nil or os.difftime(os.time(), last_sound) >= 1 then
			-- Play notification sound
			minetest.sound_play({ name = "doc_reveal", gain = 0.2 }, { to_player = playername })
			doc.data.players[playername].last_reveal_sound = os.time()
		end
	end
end

-- Reveal
function doc.mark_all_entries_as_revealed(playername)
	-- Has at least 1 new entry been revealed?
	local reveal1 = false
	for category_id, category in pairs(doc.data.categories) do
		if doc.data.players[playername].stored_data.revealed[category_id] == nil then
			doc.data.players[playername].stored_data.revealed[category_id] = {}
			doc.data.players[playername].stored_data.revealed_count[category_id] = doc.get_entry_count(category_id) - doc.data.categories[category_id].hidden_count
		end
		for entry_id, _ in pairs(category.entries) do
			if doc.data.players[playername].stored_data.revealed[category_id][entry_id] ~= true then
				doc.data.players[playername].stored_data.revealed[category_id][entry_id] = true
				doc.data.players[playername].stored_data.revealed_count[category_id] = doc.data.players[playername].stored_data.revealed_count[category_id] + 1
				reveal1 = true
			end
		end
	end

	if reveal1 then
		-- Needed because new entries are added to player's view on entry list
		doc.data.players[playername].entry_textlist_needs_updating = true

		-- Notify
		local msg = S("All help entries unlocked!")
		if minetest.get_modpath("central_message") ~= nil then
			cmsg.push_message_player(minetest.get_player_by_name(playername), msg)
		else
			minetest.chat_send_player(playername, msg)
		end

		-- Play notification sound (ignore sound limit intentionally)
		minetest.sound_play({ name = "doc_reveal", gain = 0.2 }, { to_player = playername })
		doc.data.players[playername].last_reveal_sound = os.time()
	end
end

-- Returns true if the specified entry has been viewed by the player
function doc.entry_viewed(playername, category_id, entry_id)
	local entry, entry_id = doc.get_entry(category_id, entry_id)
	if doc.data.players[playername].stored_data.viewed[category_id] == nil then
		return false
	else
		return doc.data.players[playername].stored_data.viewed[category_id][entry_id] == true
	end
end

-- Returns true if the specified entry is hidden from the player
function doc.entry_revealed(playername, category_id, entry_id)
	local entry, entry_id = doc.get_entry(category_id, entry_id)
	local hidden = doc.data.categories[category_id].entries[entry_id].hidden
	if doc.data.players[playername].stored_data.revealed[category_id] == nil then
		return not hidden
	else
		if hidden then
			return doc.data.players[playername].stored_data.revealed[category_id][entry_id] == true
		else
			return true
		end
	end
end

-- Returns category definition
function doc.get_category_definition(category_id)
	if doc.data.categories[category_id] == nil then
		return nil
	end
	return doc.data.categories[category_id].def
end

-- Returns entry definition
function doc.get_entry_definition(category_id, entry_id)
	if not doc.entry_exists(category_id, entry_id) then
		return nil
	end
	local entry, _ = doc.get_entry(category_id, entry_id)
	return entry
end

-- Opens the main documentation formspec for the player
function doc.show_doc(playername)
	if doc.get_category_count() <= 0 then
		minetest.show_formspec(playername, "doc:error_no_categories", doc.formspec_error_no_categories())
		return
	end
	local formspec = doc.formspec_core()..doc.formspec_main(playername)
	minetest.show_formspec(playername, "doc:main", formspec)
end

-- Opens the documentation formspec for the player at the specified category
function doc.show_category(playername, category_id)
	if doc.get_category_count() <= 0 then
		minetest.show_formspec(playername, "doc:error_no_categories", doc.formspec_error_no_categories())
		return
	end
	doc.data.players[playername].catsel = nil
	doc.data.players[playername].category = category_id
	doc.data.players[playername].entry = nil
	local formspec = doc.formspec_core(2)..doc.formspec_category(category_id, playername)
	minetest.show_formspec(playername, "doc:category", formspec)
end

-- Opens the documentation formspec for the player showing the specified entry in a category
function doc.show_entry(playername, category_id, entry_id, ignore_hidden)
	if doc.get_category_count() <= 0 then
		minetest.show_formspec(playername, "doc:error_no_categories", doc.formspec_error_no_categories())
		return
	end
	local entry, entry_id = doc.get_entry(category_id, entry_id)
	if ignore_hidden or doc.entry_revealed(playername, category_id, entry_id) then
		local playerdata = doc.data.players[playername]
		playerdata.category = category_id
		playerdata.entry = entry_id

		doc.mark_entry_as_viewed(playername, category_id, entry_id)
		playerdata.entry_textlist_needs_updating = true
		doc.generate_entry_list(category_id, playername)

		playerdata.catsel = playerdata.catsel_list[entry_id]
		playerdata.galidx = 1

		local formspec = doc.formspec_core(3)..doc.formspec_entry(category_id, entry_id, playername)
		minetest.show_formspec(playername, "doc:entry", formspec)
	else
		minetest.show_formspec(playername, "doc:error_hidden", doc.formspec_error_hidden(category_id, entry_id))
	end
end

-- Returns true if and only if:
-- * The specified category exists
-- * This category contains the specified entry
function doc.entry_exists(category_id, entry_id)
	if doc.data.categories[category_id] ~= nil then
		if doc.data.categories[category_id].entries[entry_id] ~= nil then
			-- Entry exists
			return true
		else
			-- Entry of this ID does not exist, so we check if there's an alias for it
			return doc.data.categories[category_id].entry_aliases[entry_id] ~= nil
		end
	else
		return false
	end
end

-- Sets the order of categories in the category list
function doc.set_category_order(categories)
	local reverse_categories = {}
	for cid=1,#categories do
		reverse_categories[categories[cid]] = cid
	end
	doc.data.category_order = categories
	for cid, cat in pairs(doc.data.categories) do
		if reverse_categories[cid] == nil then
			table.insert(doc.data.category_order, cid)
		end
	end
	reverse_categories = {}
	for cid=1, #doc.data.category_order do
		reverse_categories[categories[cid]] = cid
	end

	for cid, cat in pairs(doc.data.categories) do
		cat.order_position = reverse_categories[cid]
	end
	if set_category_order_was_called then
		minetest.log("warning", "[doc] doc.set_category_order was called again!")
	end
	set_category_order_was_called = true
end

-- Adds aliases for an entry. Attempting to open an entry by an alias name
-- results in opening the entry of the original name.
-- Aliases are true within one category only.
function doc.add_entry_aliases(category_id, entry_id, aliases)
	for a=1,#aliases do
		doc.data.categories[category_id].entry_aliases[aliases[a]] = entry_id
	end
end

-- Same as above, but only adds one alias
function doc.add_entry_alias(category_id, entry_id, alias)
	doc.data.categories[category_id].entry_aliases[alias] = entry_id
end

-- Returns number of categories
function doc.get_category_count()
	return #doc.data.category_order
end

-- Returns number of entries in category
function doc.get_entry_count(category_id)
	return doc.data.categories[category_id].entry_count
end

-- Returns how many entries have been viewed by the player
function doc.get_viewed_count(playername, category_id)
	local playerdata = doc.data.players[playername]
	if playerdata == nil then
		return nil
	end
	local count = playerdata.stored_data.viewed_count[category_id]
	if count == nil then
		playerdata.stored_data.viewed[category_id] = {}
		count = 0
		playerdata.stored_data.viewed_count[category_id] = count
		return count
	else
		return count
	end
end

-- Returns how many entries have been revealed by the player
function doc.get_revealed_count(playername, category_id)
	local playerdata = doc.data.players[playername]
	if playerdata == nil then
		return nil
	end
	local count = playerdata.stored_data.revealed_count[category_id]
	if count == nil then
		playerdata.stored_data.revealed[category_id] = {}
		count = doc.get_entry_count(category_id) - doc.data.categories[category_id].hidden_count
		playerdata.stored_data.revealed_count[category_id] = count
		return count
	else
		return count
	end
end

-- Returns how many entries are hidden from the player
function doc.get_hidden_count(playername, category_id)
	local playerdata = doc.data.players[playername]
	if playerdata == nil then
		return nil
	end
	local total = doc.get_entry_count(category_id)
	local rcount = playerdata.stored_data.revealed_count[category_id]
	if rcount == nil then
		return total
	else
		return total - rcount
	end
end

-- Returns the currently viewed entry and/or category of the player
function doc.get_selection(playername)
	local playerdata = doc.data.players[playername]
	if playerdata ~= nil then
		local cat = playerdata.category
		if cat then
			local entry = playerdata.entry
			if entry then
				return cat, entry
			else
				return cat
			end
		else
			return nil
		end
	else
		return nil
	end
end

-- Template function templates, to be used for build_formspec in doc.new_category
doc.entry_builders = {}

-- Inserts line breaks into a single paragraph and collapses all whitespace (including newlines)
-- into spaces
local linebreaker_single = function(text, linelength)
	if linelength == nil then
		linelength = 80
	end
	local remain = linelength
	local res = {}
	local line = {}
	local split = function(s)
		local res = {}
		for w in string.gmatch(s, "%S+") do
			res[#res+1] = w
		end
		return res
	end

	for _, word in ipairs(split(text)) do
		if string.len(word) + 1 > remain then
			table.insert(res, table.concat(line, " "))
			line = { word }
			remain = linelength - string.len(word)
		else
			table.insert(line, word)
			remain = remain - (string.len(word) + 1)
		end
	end

	table.insert(res, table.concat(line, " "))
	return table.concat(res, "\n")
end

-- Inserts automatic line breaks into an entire text and preserves existing newlines
local linebreaker = function(text, linelength)
	local out = ""
	for s in string.gmatch(text, "([^\n]*)") do
		local l = linebreaker_single(s, linelength)
		out = out .. l
		if(string.len(l) == 0) then
			out = out .. "\n"
		end
	end
	-- Remove last newline
	if string.len(out) >= 1 then
		out = string.sub(out, 1, string.len(out) - 1)
	end
	return out
end

-- Inserts text suitable for a textlist (including automatic word-wrap)
local text_for_textlist = function(text, linelength)
	text = linebreaker(text, linelength)
	text = minetest.formspec_escape(text)
	text = string.gsub(text, "\n", ",")
	return text
end

-- Scrollable freeform text
doc.entry_builders.text = function(data)
	local formstring = doc.widgets.text(data, doc.FORMSPEC.ENTRY_START_X, doc.FORMSPEC.ENTRY_START_Y, doc.FORMSPEC.ENTRY_WIDTH - 0.2, doc.FORMSPEC.ENTRY_HEIGHT)
	return formstring
end

doc.widgets = {}

local text_id = 1
-- Scrollable freeform text
doc.widgets.text = function(data, x, y, width, height)
	if x == nil then
		x = doc.FORMSPEC.ENTRY_START_X
	end
	if y == nil then
		y = doc.FORMSPEC.ENTRY_START_Y
	end
	if width == nil then
		width = doc.FORMSPEC.ENTRY_WIDTH
	end
	if height == nil then
		height = doc.FORMSPEC.ENTRY_HEIGHT
	end
	local baselength = 80
	local widget_basewidth = doc.FORMSPEC.WIDTH
	local linelength = math.max(20, math.floor(baselength * (width / widget_basewidth)))

	local widget_id = "doc_widget_text"..text_id
	text_id = text_id + 1
	-- TODO: Wait for Minetest to provide a native widget for scrollable read-only text with automatic line breaks.
	-- Currently, all of this had to be hacked into this script manually by using/abusing the table widget
	local formstring = "tablecolumns[text]"..
	"tableoptions[background=#00000000;highlight=#00000000;border=false]"..
	"table["..tostring(x)..","..tostring(y)..";"..tostring(width)..","..tostring(height)..";"..widget_id..";"..text_for_textlist(data, linelength).."]"
	return formstring, widget_id
end

-- Image gallery
-- Currently, only one gallery per entry is supported. TODO: Add support for multiple galleries in an entry (low priority)
doc.widgets.gallery = function(imagedata, playername, x, y, aspect_ratio, width, rows)
	if playername == nil then return nil end -- emergency exit

	local formstring = ""

	-- Defaults
	if x == nil then x = doc.FORMSPEC.ENTRY_START_X end
	if y == nil then y = doc.FORMSPEC.ENTRY_START_Y end
	if width == nil then width = doc.FORMSPEC.ENTRY_WIDTH end
	if rows == nil then rows = 3 end

	local imageindex = doc.data.players[playername].galidx
	doc.data.players[playername].maxgalidx = #imagedata
	doc.data.players[playername].galrows = rows

	if aspect_ratio == nil then aspect_ratio = (2/3) end
	local pos = 0
	local totalimagewidth, iw, ih
	local bw = 0.5
	local buttonoffset = 0
	if #imagedata > rows then
		totalimagewidth = width - bw*2
		iw = totalimagewidth / rows
		ih = iw * aspect_ratio
		formstring = formstring .. "button["..x..","..y..";"..bw..","..ih..";doc_button_gallery_prev;"..F("<").."]"
		local tt
		if rows == 1 then
			tt = F("Show previous image")
		else
			tt = F("Show previous gallery page")
		end
		formstring = formstring .. "tooltip[doc_button_gallery_prev;"..tt.."]"
		local rightx = buttonoffset + (x + rows * iw)
		formstring = formstring .. "button["..rightx..","..y..";"..bw..","..ih..";doc_button_gallery_next;"..F(">").."]"
		if rows == 1 then
			tt = F("Show next image")
		else
			tt = F("Show next gallery page")
		end
		formstring = formstring .. "tooltip[doc_button_gallery_next;"..tt.."]"
		buttonoffset = bw
	else
		totalimagewidth = width
		iw = totalimagewidth / rows
		ih = iw * aspect_ratio
	end
	for i=imageindex, math.min(#imagedata, (imageindex-1)+rows) do
		xoffset = buttonoffset + (x + pos * iw)
		formstring = formstring .. "image["..xoffset..","..y..";"..iw..","..ih..";"..imagedata[i].image.."]"
		pos = pos + 1
	end
	local bw, bh

	return formstring, ih
end

-- Direct formspec
doc.entry_builders.formspec = function(data)
	return data
end

--[[ Internal stuff ]]

-- Loading and saving player data
do
	local filepath = minetest.get_worldpath().."/doc.mt"
	local file = io.open(filepath, "r")
	if file then
		minetest.log("action", "[doc] doc.mt opened.")
		local string = file:read()
		io.close(file)
		if(string ~= nil) then
			local savetable = minetest.deserialize(string)
			for name, players_stored_data in pairs(savetable.players_stored_data) do
				doc.data.players[name] = {}
				doc.data.players[name].stored_data = players_stored_data
			end
			minetest.debug("[doc] doc.mt successfully read.")
		end
	end
end

function doc.save_to_file()
	local savetable = {}
	savetable.players_stored_data = {}
	for name, playerdata in pairs(doc.data.players) do
		savetable.players_stored_data[name] = playerdata.stored_data
	end

	local savestring = minetest.serialize(savetable)

	local filepath = minetest.get_worldpath().."/doc.mt"
	local file = io.open(filepath, "w")
	if file then
		file:write(savestring)
		io.close(file)
		minetest.log("action", "[doc] Wrote player data into "..filepath..".")
	else
		minetest.log("error", "[doc] Failed to write player data into "..filepath..".")
	end
end

minetest.register_on_leaveplayer(function(player)
	doc.save_to_file()
end)

minetest.register_on_shutdown(function()
	minetest.log("action", "[doc] Server shuts down. Rescuing player data into doc.mt.")
	doc.save_to_file()
end)

--[[ Functions for internal use ]]

function doc.formspec_core(tab)
	if tab == nil then tab = 1 else tab = tostring(tab) end
	return "size["..doc.FORMSPEC.WIDTH..","..doc.FORMSPEC.HEIGHT.."]tabheader[0,0;doc_header;"..
	minetest.formspec_escape(S("Category list")) .. "," ..
	minetest.formspec_escape(S("Entry list")) .. "," ..
	minetest.formspec_escape(S("Entry")) .. ";"
	..tab..";true;false]"
end

function doc.formspec_main(playername)
	local formstring = "label[0,0;"..minetest.formspec_escape(DOC_INTRO) .. "\n"
	if doc.get_category_count() >= 1 then
		formstring = formstring .. F("Please select a category you wish to learn more about:").."]"
		if doc.get_category_count() <= (CATEGORYFIELDSIZE.WIDTH * CATEGORYFIELDSIZE.HEIGHT)  then
			local y = 1
			local x = 1
			-- Show all categories in order
			for c=1,#doc.data.category_order do
				local id = doc.data.category_order[c]
				local data = doc.data.categories[id]
				-- Skip categories which do not exist
				if data ~= nil then
					-- Category buton
					local button = "button["..((x-1)*3)..","..y..";3,1;doc_button_category_"..id..";"..minetest.formspec_escape(data.def.name).."]"
					local tooltip = ""
					-- Optional description
					if data.def.description ~= nil then
					tooltip = "tooltip[doc_button_category_"..id..";"..minetest.formspec_escape(data.def.description).."]"
					end
					formstring = formstring .. button .. tooltip
					y = y + 1
					if y > CATEGORYFIELDSIZE.HEIGHT then
						x = x + 1
						y = 1
					end
				end
			end
		else
			formstring = formstring .. "textlist[0,1;"..(doc.FORMSPEC.WIDTH-0.2)..","..(doc.FORMSPEC.HEIGHT-2)..";doc_mainlist;"
			for c=1,#doc.data.category_order do
				local id = doc.data.category_order[c]
				local data = doc.data.categories[id]
				formstring = formstring .. minetest.formspec_escape(data.def.name)
				if c < #doc.data.category_order then
					formstring = formstring .. ","
				end
			end
			local sel = doc.data.categories[doc.data.players[playername].category]
			if sel ~= nil then
				formstring = formstring .. ";"
				formstring = formstring .. doc.data.categories[doc.data.players[playername].category].order_position
			end
			formstring = formstring .. "]"
			formstring = formstring .. "button[0,"..(doc.FORMSPEC.HEIGHT-1)..";3,1;doc_button_goto_category;"..F("Show category").."]"
		end
	else
		formstring = formstring .. "]"
	end
	return formstring
end

function doc.formspec_error_no_categories()
	local formstring = "size[8,6]textarea[0.25,0;8,6;;"
	formstring = formstring ..
	minetest.formspec_escape(
		DOC_INTRO .. "\n\n" ..
		S("Error: No help available.") .. "\n\n" ..
S("No categories have been registered, but the Documentation System is useless without them.\nThe main Documentation System mod (doc) does not come with help contents on its own, it needs additional mods to add help content. Please make sure such mods are enabled on for this world, and try again.")) .. "\n\n" ..
S("Recommended mods: doc_basics, doc_items, doc_identifier.")
	formstring = formstring .. ";]button_exit[3,5;2,1;okay;"..F("OK").."]"
	return formstring
end

function doc.formspec_error_hidden(category_id, entry_id)
	local formstring = "size[8,6]textarea[0.25,0;8,6;;"
	formstring = formstring .. minetest.formspec_escape(
	DOC_INTRO .. "\n\n" ..
	S("Error: Access denied.") .. "\n\n" ..
	S("Access to the requested entry has been denied; this entry is secret. You may unlock access by more playing. Figure out on your own how to unlock this entry."))
	formstring = formstring .. ";]button_exit[3,5;2,1;okay;"..F("OK").."]"
	return formstring
end

-- Returns the entry definition and true entry ID of an entry, taking aliases into account
function doc.get_entry(category_id, entry_id)
	local category = doc.data.categories[category_id]
	local entry = category.entries[entry_id]
	local resolved_entry_id = entry_id
	if entry == nil then
		resolved_entry_id = doc.data.categories[category_id].entry_aliases[entry_id]
		if resolved_entry_id ~= nil then
			entry = category.entries[resolved_entry_id]
		end
	end
	return entry, resolved_entry_id
end

function doc.generate_entry_list(cid, playername)
	local formstring
	if doc.data.players[playername].entry_textlist == nil
	or doc.data.players[playername].catsel_list == nil
	or doc.data.players[playername].category ~= cid
	or doc.data.players[playername].entry_textlist_needs_updating == true then
		local entry_textlist = "textlist[0,1;"..(doc.FORMSPEC.WIDTH-0.2)..","..(doc.FORMSPEC.HEIGHT-2)..";doc_catlist;"
		local counter = 0
		doc.data.players[playername].entry_ids = {}
		local entries = doc.get_sorted_entry_names(cid)
		doc.data.players[playername].catsel_list = {}
		for i=1, #entries do
			local eid = entries[i]
			local edata = doc.data.categories[cid].entries[eid]
			if doc.entry_revealed(playername, cid, eid) then
				table.insert(doc.data.players[playername].entry_ids, eid)
				doc.data.players[playername].catsel_list[eid] = counter + 1
				-- Colorize entries based on viewed status
				-- Not viewed: Cyan
				local viewedprefix = "#00FFFF"
				local name = edata.name
				if name == nil or name == "" then
					name = string.format(S("Nameless entry (%s)"), eid)
					if doc.entry_viewed(playername, cid, eid) then
						viewedprefix = "#FF4444"
					else
						viewedprefix = "#FF0000"
					end
				elseif doc.entry_viewed(playername, cid, eid) then
					-- Viewed: White
					viewedprefix = "#FFFFFF"
				end
				entry_textlist = entry_textlist .. viewedprefix .. minetest.formspec_escape(name) .. ","
				counter = counter + 1
			end
		end
		if counter >= 1  then
			entry_textlist = string.sub(entry_textlist, 1, #entry_textlist-1)
		end
		local catsel = doc.data.players[playername].catsel
		if catsel then
			entry_textlist = entry_textlist .. ";"..catsel
		end
		entry_textlist = entry_textlist .. "]"
		doc.data.players[playername].entry_textlist = entry_textlist
		formstring = entry_textlist
		doc.data.players[playername].entry_textlist_needs_updating = false
	else
		formstring = doc.data.players[playername].entry_textlist
	end
	return formstring
end

function doc.get_sorted_entry_names(cid)
	local sort_table = {}
	local entry_table = {}
	local cat = doc.data.categories[cid]
	local used_eids = {}
	-- Helper function to extract the entry ID out of the output table
	local extract = function(entry_table)
		local eids = {}
		for k,v in pairs(entry_table) do
			local eid = v.eid
			table.insert(eids, eid)
		end
		return eids
	end
	-- Predefined sorting
	if cat.def.sorting == "custom" then
		for i=1,#cat.def.sorting_data do
			local new_entry = table.copy(cat.entries[cat.def.sorting_data[i]])
			new_entry.eid = cat.def.sorting_data[i]
			table.insert(entry_table, new_entry)
			used_eids[cat.def.sorting_data[i]] = true
		end
	end
	for eid,entry in pairs(cat.entries) do
		local new_entry = table.copy(entry)
		new_entry.eid = eid
		if not used_eids[eid] then
			table.insert(entry_table, new_entry)
		end
		table.insert(sort_table, entry.name)
	end
	if cat.def.sorting == "custom" then
		return extract(entry_table)
	else
		table.sort(sort_table)
	end
	local reverse_sort_table = table.copy(sort_table)
	for i=1, #sort_table do
		reverse_sort_table[sort_table[i]] = i
	end
	local comp
	if cat.def.sorting ~= "nosort" then
		-- Sorting by user function
		if cat.def.sorting == "function" then
			comp = cat.def.sorting_data
		-- Alphabetic sorting
		elseif cat.def.sorting == "abc" or cat.def.sorting == nil then
			comp = function(e1, e2)
				if reverse_sort_table[e1.name] < reverse_sort_table[e2.name] then return true else return false end
			end
		end
		table.sort(entry_table, comp)
	end

	return extract(entry_table)
end

function doc.formspec_category(id, playername)
	local formstring
	if id == nil then
		formstring = "label[0,0;"..F("Help > (No Category)") .. "]"
		formstring = formstring .. "label[0,0.5;"..F("You haven't chosen a category yet. Please choose one in the category list first.").."]"
		formstring = formstring .. "button[0,1;3,1;doc_button_goto_main;"..F("Go to category list").."]"
	else
		formstring = "label[0,0;"..minetest.formspec_escape(string.format(S("Help > %s"), doc.data.categories[id].def.name)).."]"
		local total = doc.get_entry_count(id)
		if total >= 1 then
			local revealed = doc.get_revealed_count(playername, id)
			if revealed == 0 then
				formstring = formstring .. "label[0,0.5;"..F("Currently all entries in this category are hidden from you.\nUnlock new entries by proceeding in the game.").."]"
				formstring = formstring .. "button[0,1.5;3,1;doc_button_goto_main;"..F("Go to category list").."]"
			else
				formstring = formstring .. "label[0,0.5;"..F("This category has the following entries:").."]"
				formstring = formstring .. doc.generate_entry_list(id, playername)
				formstring = formstring .. "button[0,"..(doc.FORMSPEC.HEIGHT-1)..";3,1;doc_button_goto_entry;"..F("Show entry").."]"
				formstring = formstring .. "label[8,8;"..minetest.formspec_escape(string.format(S("Number of entries: %d"), total)).."\n"
				local viewed = doc.get_viewed_count(playername, id)
				local hidden = total - revealed
				local new = total - viewed - hidden
				-- TODO/FIXME: Check if number of hidden/viewed entries is always correct
				if viewed < total then
					formstring = formstring .. minetest.formspec_escape(string.format(S("New entries: %d"), new))
					if hidden > 0 then
						formstring = formstring .. "\n"
						formstring = formstring .. minetest.formspec_escape(string.format(S("Hidden entries: %d"), hidden)).."]"
					else
						formstring = formstring .. "]"
					end
				else
					formstring = formstring .. F("All entries read.").."]"
				end
			end
		else
			formstring = formstring .. "label[0,0.5;"..F("This category is empty.").."]"
			formstring = formstring .. "button[0,1.5;3,1;doc_button_goto_main;"..F("Go to category list").."]"
		end
	end
	return formstring
end

function doc.formspec_entry_navigation(category_id, entry_id)
	if doc.get_entry_count(category_id) < 1 then
		return ""
	end
	local formstring = ""
	formstring = formstring .. "button[10,8.5;1,1;doc_button_goto_prev;"..F("<").."]"
	formstring = formstring .. "button[11,8.5;1,1;doc_button_goto_next;"..F(">").."]"
	formstring = formstring .. "tooltip[doc_button_goto_prev;"..F("Show previous entry").."]"
	formstring = formstring .. "tooltip[doc_button_goto_next;"..F("Show next entry").."]"
	return formstring
end

function doc.formspec_entry(category_id, entry_id, playername)
	local formstring
	if category_id == nil then
		formstring = "label[0,0;"..F("Help > (No Category)") .. "]"
		formstring = formstring .. "label[0,0.5;"..F("You haven't chosen a category yet. Please choose one in the category list first.").."]"
		formstring = formstring .. "button[0,1;3,1;doc_button_goto_main;"..F("Go to category list").."]"
	elseif entry_id == nil then
		formstring = "label[0,0;"..minetest.formspec_escape(string.format(S("Help > %s > (No Entry)"), doc.data.categories[category_id].def.name)) .. "]"
		if doc.get_entry_count(category_id) >= 1 then
			formstring = formstring .. "label[0,0.5;"..F("You haven't chosen an entry yet. Please choose one in the entry list first.").."]"
			formstring = formstring .. "button[0,1.5;3,1;doc_button_goto_category;"..F("Go to entry list").."]"
		else
			formstring = formstring .. "label[0,0.5;"..F("This category does not have any entries.").."]"
			formstring = formstring .. "button[0,1.5;3,1;doc_button_goto_main;"..F("Go to category list").."]"
		end
	else

		local category = doc.data.categories[category_id]
		local entry = doc.get_entry(category_id, entry_id)
		local ename = entry.name
		if ename == nil or ename == "" then
			ename = string.format(S("Nameless entry (%s)"), entry_id)
		end
		formstring = "label[0,0;"..minetest.formspec_escape(string.format(S("Help > %s > %s"), category.def.name, ename)).."]"
		formstring = formstring .. category.def.build_formspec(entry.data, playername)
		formstring = formstring .. doc.formspec_entry_navigation(category_id, entry_id)
	end
	return formstring
end

function doc.process_form(player,formname,fields)
	local playername = player:get_player_name()
	--[[ process clicks on the tab header ]]
	if(formname == "doc:main" or formname == "doc:category" or formname == "doc:entry") then
		if fields.doc_header ~= nil then
			local tab = tonumber(fields.doc_header)
			local formspec, subformname, contents
			local cid, eid
			cid = doc.data.players[playername].category
			eid = doc.data.players[playername].entry
			if(tab==1) then
				contents = doc.formspec_main(playername)
				subformname = "main"
			elseif(tab==2) then
				contents = doc.formspec_category(cid, playername)
				subformname = "category"
			elseif(tab==3) then
				doc.data.players[playername].galidx = 1
				contents = doc.formspec_entry(cid, eid, playername)
				if cid ~= nil and eid ~= nil then
					doc.mark_entry_as_viewed(playername, cid, eid)
				end
				subformname = "entry"
			end
			formspec = doc.formspec_core(tab)..contents
			minetest.show_formspec(playername, "doc:" .. subformname, formspec)
			return
		end
	end
	if(formname == "doc:main") then
		for cid,_ in pairs(doc.data.categories) do
			if fields["doc_button_category_"..cid] then
				doc.data.players[playername].catsel = nil
				doc.data.players[playername].category = cid
				doc.data.players[playername].entry = nil
				doc.data.players[playername].entry_textlist_needs_updating = true
				local formspec = doc.formspec_core(2)..doc.formspec_category(cid, playername)
				minetest.show_formspec(playername, "doc:category", formspec)
				break
			end
		end
		if fields["doc_mainlist"] then
			local event = minetest.explode_textlist_event(fields["doc_mainlist"])
			local cid = doc.data.category_order[event.index]
			if cid ~= nil then
				if event.type == "CHG" then
					doc.data.players[playername].catsel = nil
					doc.data.players[playername].category = cid
					doc.data.players[playername].entry = nil
					doc.data.players[playername].entry_textlist_needs_updating = true
				elseif event.type == "DCL" then
					doc.data.players[playername].catsel = nil
					doc.data.players[playername].category = cid
					doc.data.players[playername].entry = nil
					doc.data.players[playername].entry_textlist_needs_updating = true
					local formspec = doc.formspec_core(2)..doc.formspec_category(cid, playername)
					minetest.show_formspec(playername, "doc:category", formspec)
				end
			end
		end
		if fields["doc_button_goto_category"] then
			local cid = doc.data.players[playername].category
			doc.data.players[playername].catsel = nil
			doc.data.players[playername].entry = nil
			doc.data.players[playername].entry_textlist_needs_updating = true
			local formspec = doc.formspec_core(2)..doc.formspec_category(cid, playername)
			minetest.show_formspec(playername, "doc:category", formspec)
		end
	elseif(formname == "doc:category") then
		if fields["doc_button_goto_entry"] then
			local cid = doc.data.players[playername].category
			if cid ~= nil then
				local eid = nil
				local eids, catsel = doc.data.players[playername].entry_ids, doc.data.players[playername].catsel
				if eids ~= nil and catsel ~= nil then
					eid = eids[catsel]
				end
				doc.data.players[playername].galidx = 1
				local formspec = doc.formspec_core(3)..doc.formspec_entry(cid, eid, playername)
				minetest.show_formspec(playername, "doc:entry", formspec)
				doc.mark_entry_as_viewed(playername, cid, eid)
			end
		end
		if fields["doc_button_goto_main"] then
			local formspec = doc.formspec_core(1)..doc.formspec_main(playername)
			minetest.show_formspec(playername, "doc:main", formspec)
		end
		if fields["doc_catlist"] then
			local event = minetest.explode_textlist_event(fields["doc_catlist"])
			if event.type == "CHG" then
				doc.data.players[playername].catsel = event.index
				doc.data.players[playername].entry = doc.data.players[playername].entry_ids[event.index]
				doc.data.players[playername].entry_textlist_needs_updating = true
			elseif event.type == "DCL" then
				local cid = doc.data.players[playername].category
				local eid = nil
				local eids, catsel = doc.data.players[playername].entry_ids, event.index
				if eids ~= nil and catsel ~= nil then
					eid = eids[catsel]
				end
				doc.mark_entry_as_viewed(playername, cid, eid)
				doc.data.players[playername].entry_textlist_needs_updating = true
				doc.data.players[playername].galidx = 1
				local formspec = doc.formspec_core(3)..doc.formspec_entry(cid, eid, playername)
				minetest.show_formspec(playername, "doc:entry", formspec)
			end
		end
	elseif(formname == "doc:entry") then
		if fields["doc_button_goto_main"] then
			local formspec = doc.formspec_core(1)..doc.formspec_main(playername)
			minetest.show_formspec(playername, "doc:main", formspec)
		elseif fields["doc_button_goto_category"] then
			local formspec = doc.formspec_core(2)..doc.formspec_category(doc.data.players[playername].category, playername)
			minetest.show_formspec(playername, "doc:category", formspec)
		elseif fields["doc_button_goto_next"] then
			if doc.data.players[playername].catsel == nil then return end -- emergency exit
			local eids = doc.data.players[playername].entry_ids
			local cid = doc.data.players[playername].category
			local new_catsel= doc.data.players[playername].catsel + 1
			local new_eid = eids[new_catsel]
			if #eids > 1 and new_catsel <= #eids then
				doc.mark_entry_as_viewed(playername, cid, new_eid)
				doc.data.players[playername].catsel = new_catsel
				doc.data.players[playername].entry = new_eid
				doc.data.players[playername].galidx = 1
				local formspec = doc.formspec_core(3)..doc.formspec_entry(cid, new_eid, playername)
				minetest.show_formspec(playername, "doc:entry", formspec)
			end
		elseif fields["doc_button_goto_prev"] then
			if doc.data.players[playername].catsel == nil then return end -- emergency exit
			local eids = doc.data.players[playername].entry_ids
			local cid = doc.data.players[playername].category
			local new_catsel= doc.data.players[playername].catsel - 1
			local new_eid = eids[new_catsel]
			if #eids > 1 and new_catsel >= 1 then
				doc.mark_entry_as_viewed(playername, cid, new_eid)
				doc.data.players[playername].catsel = new_catsel
				doc.data.players[playername].entry = new_eid
				doc.data.players[playername].galidx = 1
				local formspec = doc.formspec_core(3)..doc.formspec_entry(cid, new_eid, playername)
				minetest.show_formspec(playername, "doc:entry", formspec)
			end
		elseif fields["doc_button_gallery_prev"] then
			local cid, eid = doc.get_selection(playername)
			if doc.data.players[playername].galidx - doc.data.players[playername].galrows > 0 then
				doc.data.players[playername].galidx = doc.data.players[playername].galidx - doc.data.players[playername].galrows
			end
			local formspec = doc.formspec_core(3)..doc.formspec_entry(cid, eid, playername)
			minetest.show_formspec(playername, "doc:entry", formspec)
		elseif fields["doc_button_gallery_next"] then
			local cid, eid = doc.get_selection(playername)
			if doc.data.players[playername].galidx + doc.data.players[playername].galrows <= doc.data.players[playername].maxgalidx then
				doc.data.players[playername].galidx = doc.data.players[playername].galidx + doc.data.players[playername].galrows
			end
			local formspec = doc.formspec_core(3)..doc.formspec_entry(cid, eid, playername)
			minetest.show_formspec(playername, "doc:entry", formspec)
		end
	end
end

minetest.register_on_player_receive_fields(doc.process_form)

minetest.register_chatcommand("doc", {
	params = "",
	description = S("Open documentation system"),
	privs = {},
	func = function(playername, param)
		doc.show_doc(playername)
	end,
	}
)

minetest.register_on_joinplayer(function(player)
	local playername = player:get_player_name()
	local playerdata = doc.data.players[playername]
	if playerdata == nil then
		-- Initialize player data
		doc.data.players[playername] = {}
		playerdata = doc.data.players[playername]
		-- Gallery index, stores current index of first displayed image in a gallery
		playerdata.galidx = 1
		-- Maximum gallery index (index of last image in gallery)
		playerdata.maxgalidx = 1
		-- Number of rows in an gallery of the current entry
		playerdata.galrows = 1
		-- Table for persistant data
		playerdata.stored_data = {}
		-- Contains viewed entries
		playerdata.stored_data.viewed = {}
		-- Count viewed entries
		playerdata.stored_data.viewed_count = {}
		-- Contains revealed/unhidden entries
		playerdata.stored_data.revealed = {}
		-- Count revealed entries
		playerdata.stored_data.revealed_count = {}
	else
		-- Completely rebuild viewed and revealed counts from scratch
		for cid, cat in pairs(doc.data.categories) do
			if playerdata.stored_data.viewed[cid] == nil then
				playerdata.stored_data.viewed[cid] = {}
			end
			if playerdata.stored_data.revealed[cid] == nil then
				playerdata.stored_data.revealed[cid] = {}
			end
			local vc = 0
			local rc = doc.get_entry_count(cid) - doc.data.categories[cid].hidden_count
			for eid, entry in pairs(cat.entries) do
				if playerdata.stored_data.viewed[cid][eid] then
					vc = vc + 1
					playerdata.stored_data.revealed[cid][eid] = true
				end
				if playerdata.stored_data.revealed[cid][eid] and entry.hidden then
					rc = rc + 1
				end
			end
			playerdata.stored_data.viewed_count[cid] = vc
			playerdata.stored_data.revealed_count[cid] = rc
		end
	end
end)

minetest.register_on_leaveplayer(function(player)
	doc.data.players[player:get_player_name()] = nil
end)

---[[ Add buttons for inventory mods ]]
-- Unified Inventory
if minetest.get_modpath("unified_inventory") ~= nil then
	unified_inventory.register_button("doc", {
		type = "image",
		image = "doc_button_icon_hires.png",
		tooltip = S("Documentation System"),
		action = function(player)
			doc.show_doc(player:get_player_name())
		end,
	})
end

minetest.register_privilege("doc_reveal", {
	description = S("Allows you to reveal all hidden help entries with /doc_reveal"),
	give_to_singleplayer = false
})

minetest.register_chatcommand("doc_reveal", {
	params = "",
	description = S("Reveals all hidden help entries to you"),
	privs = { doc_reveal = true },
	func = function(name, param)
		doc.mark_all_entries_as_revealed(name)
	end,
})
