--[[
ACQ BATCH MODE, reading several macrolua files, when an ACQ is detected as finished, a counter is incremented and next one is loaded and started...
]]

--print("ACQ BATCH MODE")

ACQ_BATCH = {
	fileFolder = "./_macroLua/",
	batchFile = "ACQ_batch_list.lua",
	readBatchFile = function()
		local file = ACQ_BATCH.fileFolder..ACQ_BATCH.batchFile
		if(io.open(file)) then
			dofile(file, "r")
			local str = strBatchList
			strBatchList = nil
			return str
		else
			print("Error while reading batch file '", ACQ_BATCH.batchFile, "'")
			return ""
		end
	end,
	prepare = function()
		local str = ACQ_BATCH.readBatchFile(ACQ_BATCH.fileFolder..ACQ_BATCH.batchFile)
		local list = str:split(";")
		
		for k, name in ipairs(list) do
			-- check if file is accessible...
			local file = ACQ_BATCH.fileFolder..name
			
			if(io.open(file)) then
				-- build table with available info in file name...
				local tbl = ACQ_BATCH.readMacroInfo(file)
				tbl["fullPath"] = file
				tbl["fileName"] = name
				
				--aft(tbl, "-->")
				
				table.insert(ACQ_BATCH.list, tbl)
			else
				table.insert(ACQ_BATCH.checkErrors, "--> file '"..file.."' not found...")
			end
			
			--aft(ACQ_BATCH.list)
		end
	end,
	readMacroInfo = function (file)
		local file = io.input(file)
		local tbl = {}
		
		for l in file:lines() do
			local line = trim(l)
			if line ~= nil and string.len(line) > 0 then
				local data = trim(string.sub(line, 0, 2))
				
				if data == "##" then
					local str = trim(string.sub(line, 3))
					local a = str:split(";")
					
					if str ~= "" and table.getn(a) == 2 then
						tbl[a[1]] = a[2]
					else
						--print("readMacroInfo: splitting returns more than 2 items for string '"..str.."'")
					end
				end
			end
		end
		
		file:close()
		
		return tbl
	end,
	checkStatusOk = function() return table.getn(ACQ_BATCH.checkErrors) == 0 and ACQ_BATCH.nbFile() > 0 end,
	checkErrors = {}, -- will contain errors found while feeding ACQ_BATCH.list...
	currentIndex = 0, -- index allowing to get current macrolua file to read in ACQ_BATCH.list table...
	nbFile = function() return table.getn(ACQ_BATCH.list) end,
	list = {}, -- will contain table with all files to read and details. Index starts at 1...
	viewListContent = function()
		for k, v in pairs(ACQ_BATCH.list) do
			aft(v, "--> #"..k)
		end
	end,
	incrementFileIndex = function() ACQ_BATCH.currentIndex = ACQ_BATCH.currentIndex + 1 end,
	getCurrentFileName = function()
		if ACQ_BATCH.list[ACQ_BATCH.currentIndex] == nil then
			-- no more file to load, stop here...
			ACQ.continueProcess = false
			print("ACQ BATCH : no more files to load...")
			return ""
		end
		
		return ACQ_BATCH.list[ACQ_BATCH.currentIndex].fullPath
	end,
}

-- launch ACQ_BATCH preparation process...
ACQ_BATCH.prepare()

if(ACQ_BATCH.checkStatusOk() == false) then
	print("Errors found while feeding ACQ_BATCH.list :")
	aft(ACQ_BATCH.checkErrors, "")
	return
end

