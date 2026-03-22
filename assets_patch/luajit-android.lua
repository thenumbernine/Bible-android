-- this is the LuaJIT app's main.lua is currently pointed
-- it is distinct of the SDLLuaJIT in that it has a minimal bootstrap that points it squarely to lua-java and the assets apk loader
-- from there I will load more files from here
-- and then write stupid android apps
local assert = require 'ext.assert'
local table = require 'ext.table'
local string = require 'ext.string'
local path = require 'ext.path'
local ffi = require 'ffi'
local J = require 'java'


local Activity = J.android.app.Activity
local LinearLayout = J.android.widget.LinearLayout


local callbacks = {}

-- maybe I should by default make all handlers that call through to super ...
do
	local callbackNames = {}
	for name,methodsForName in pairs(Activity._methods) do
		for _,method in ipairs(methodsForName) do
			if method._class == 'android.app.Activity' then
				callbackNames[name] = true	-- do as a set so multiple signature methods will only get one callback (since lua invokes it by name below)
			end
		end
	end
	for name in pairs(callbackNames) do
		-- set up default callback handler to run super() of whatever args we are given
		callbacks[name] = function(activity, ...)
			local super = activity.super
			return super[name](super, ...)
		end
	end
end


----------- some support functions

local nextMenuID = 0
local function getNextMenu()
	nextMenuID = nextMenuID + 1
	return nextMenuID
end

local nextActivityID = Activity.RESULT_FIRST_USER
local function getNextActivity()
	nextActivityID = nextActivityID + 1
	return nextActivityID
end




local BookListViewAdapter
local activity
local listView
local readerView
local textView
local fontSize = 20

local books = table()
local booksForName = {}
local allChapters = table()
local currentBook
local currentChapter

local function showVerseList()
	-- assumes currentBook and currentChapter is set
	local title = currentBook.name
	if #currentBook.chapters > 1 then
		title = title .. ' '..tostring(currentChapter.no)
	end
	activity:setTitle(title)

	textView:setText(
		currentChapter.lines:mapi(function(line)
			if line.verseno then
				return line.verseno..': '..line.text
			else
				return line.text
			end
		end):concat'\n'
	)
	activity:setContentView(readerView)
end

local showLevel
local function show()
	if showLevel == 1 then
		activity:setTitle'Bible App'
		listView:setAdapter(BookListViewAdapter())
		activity:setContentView(listView)
	elseif showLevel == 2 then
		-- assumes currentBook is set
		activity:setTitle(currentBook.name)
		listView:setAdapter(ChapterListViewAdapter())
		activity:setContentView(listView)
	elseif showLevel == 3 then
		-- assumes currentBook and currentChapter is set
		showVerseList()
	end
end

local function showAbout()
	activity:setTitle'About'
	textView:setText[[
Bible App

Copyright (c) 2026 Christopher E. Moore

https://github.com/thenumbernine/Bible-android

If you like this app, please consider supporting it.
Donations are greatly appreciated.
https://buymeacoffee.com/thenumbernine
]]
	activity:setContentView(readerView)
end

local function refreshFontSize()
	textView:setTextSize(J.android.util.TypedValue.COMPLEX_UNIT_SP, fontSize)
end


--[[
what should be in here?
1) display function (show() vs showAbout() etc)
2) state (showLevel, currentBook, currentChapter)
--]]

--[[
args:
	show = how to show
		vars:
	showLevel
	currentBook
	currentChapter
--]]
local function showHistory(args)
	showLevel = args.showLevel or showLevel
	currentBook = args.currentBook or currentBook
	currentChapter = args.currentChapter or currentChapter
	args.show()
end

local backHistory = table()
local function showAndAddHistory(args)
	backHistory:insert(args)
	showHistory(args)
end

local prevOnCreate = callbacks.onCreate
callbacks.onCreate = function(activity_, savedInstanceState, ...)
	prevOnCreate(activity_, savedInstances, ...)
	
	-- save here
	activity = activity_

	local ViewGroup = J.android.view.ViewGroup

	readerView = J.android.widget.ScrollView(activity)
	readerView:setLayoutParams(ViewGroup.LayoutParams(
		ViewGroup.LayoutParams.MATCH_PARENT,
		ViewGroup.LayoutParams.MATCH_PARENT
	))

	textView = J.android.widget.TextView(activity)
	textView:setLayoutParams(ViewGroup.LayoutParams(
		ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.MATCH_PARENT
	))
	textView:setPadding(16, 16, 16, 16)
	refreshFontSize()
	textView:setTextIsSelectable(true)
	readerView:addView(textView)

	listView = J.android.widget.ListView(activity)

	-- while we're here ...
	local data = activity:readAssetPath'bible/kjv.txt':_toStr()
	local filelineno = 1
	for line in data:gmatch'[^\n]+' do
		local section, text = line:match'^([^\t]+)\t(.*)$'
		local bookname, chapterno, verseno = section:match'^(.*) (%d+):(%d+)$'
		if not bookname then
			bookname = section
			chapterno = 1
		else
			chapterno = tonumber(chapterno)
			verseno = tonumber(verseno)
		end
		local book = booksForName[bookname]
		if not book then
			book = {
				name = bookname,
				menuID = getNextMenu(),
				chapters = table(),
				chaptersForNo = {},
			}
			books:insert(book)
			booksForName[bookname] = book
		end
		local chapter = book.chaptersForNo[chapterno]
		if not chapter then
			chapter = {
				no = chapterno,
				lines = table(),
				menuID = getNextMenu(),
				book = book,
			}
			allChapters:insert(chapter)
			book.chaptersForNo[chapterno] = chapter
			book.chapters:insert(chapter)
		end
		chapter.lines:insert{verseno=verseno, text=text}
		filelineno = filelineno + 1
	end

	local BaseAdapter = J.android.widget.BaseAdapter

	local numCols = 5
	-- this is going to be a list-of-rows, and each row will have numCols buttons in it...
	ChapterListViewAdapter = BaseAdapter:_subclass{
		isPublic = true,
		methods = {
			getCount = {
				isPublic = true,
				sig = {'int'},
				value = function(this)
					return math.ceil(#currentBook.chapters / numCols)
				end,
			},
			getItem = {
				isPublic = true,
				sig = {'java.lang.Object', 'int'},
				value = function(this, position) return J.Integer(position) end,
			},
			getItemId = {
				isPublic = true,
				sig = {'long', 'int'},
				value = function(this, position) return position end,
			},
			getView = {
				isPublic = true,
				sig = {'android.view.View', 'int', 'android.view.View', 'android.view.ViewGroup'},
				value = function(this, position, convertView, parent)
					local View = J.android.view.View
					local ViewGroup = J.android.view.ViewGroup
					local Button = J.android.widget.Button

					local layout = LinearLayout(activity)
					layout:setOrientation(LinearLayout.HORIZONTAL)
					layout:setWeightSum(numCols)

					local startIndex = 1 + numCols * position
					local endIndex = numCols * (position + 1)
					for chapterIndex=startIndex, endIndex do
						local chapter = currentBook.chapters[chapterIndex]
						if not chapter then break end

						local button = Button(activity)

						button:setLayoutParams(LinearLayout.LayoutParams(
							0,	-- width = 0dp
							LinearLayout.LayoutParams.WRAP_CONTENT,	-- height
							1	-- layout_weight
						))

						button:setText(tostring(chapter.no))
						button:setOnClickListener(View.OnClickListener(function()
							currentChapter = chapter
							showAndAddHistory{
								showLevel = 3,
								show = show,
							}
						end))
						layout:addView(button)
					end

					return layout
				end,
			},
		},
	}

	BookListViewAdapter = BaseAdapter:_subclass{
		isPublic = true,
		methods = {
			getCount = {
				isPublic = true,
				sig = {'int'},
				value = function(this) return #books end,
			},
			getItem = {
				isPublic = true,
				sig = {'java.lang.Object', 'int'},
				value = function(this, position) return J.Integer(position) end,
			},
			getItemId = {
				isPublic = true,
				sig = {'long', 'int'},
				value = function(this, position) return position end,
			},
			getView = {
				isPublic = true,
				sig = {'android.view.View', 'int', 'android.view.View', 'android.view.ViewGroup'},
				value = function(this, position, convertView, parent)
					local View = J.android.view.View
					local ViewGroup = J.android.view.ViewGroup
					local Button = J.android.widget.Button

					local layout = LinearLayout(activity)
					layout:setOrientation(LinearLayout.HORIZONTAL)

					local button = Button(activity)

					button:setLayoutParams(LinearLayout.LayoutParams(
						LinearLayout.LayoutParams.MATCH_PARENT,
						LinearLayout.LayoutParams.WRAP_CONTENT
					))

					local bookIndex = position+1
					local book = books[bookIndex]
					button:setText(book.name)
					button:setOnClickListener(View.OnClickListener(function()
						currentBook = book
						if #book.chapters == 1 then
							showAndAddHistory{
								currentChapter = currentBook.chapters[1],
								showLevel = 3,	-- verse-list
								show = show,
							}
						else
							showAndAddHistory{
								showLevel = 2,	-- chapter-list
								show = show,
							}
						end
					end))
					layout:addView(button)

					return layout
				end,
			},
		},
	}

	showAndAddHistory{
		showLevel = 1,	-- 1 = books, 2 = chapters, 3 = content
		show = show,
	}
end

local menuOpenBooks = getNextMenu()
local menuChapterPrev = getNextMenu()
local menuFontPlus = getNextMenu()
local menuFontMinus = getNextMenu()
local menuChapterNext = getNextMenu()
local menuOpenAbout = getNextMenu()

local prevOnCreateOptionsMenu = callbacks.onCreateOptionsMenu
callbacks.onCreateOptionsMenu = function(activity, menu, ...)
	prevOnCreateOptionsMenu(activity, menu, ...)
	menu:add(0, menuChapterPrev, 0, '<')
		:setShowAsAction(J.android.view.MenuItem.SHOW_AS_ACTION_ALWAYS)
	menu:add(0, menuFontPlus, 1, '+')
		:setShowAsAction(J.android.view.MenuItem.SHOW_AS_ACTION_ALWAYS)
	menu:add(0, menuFontMinus, 2, '-')
		:setShowAsAction(J.android.view.MenuItem.SHOW_AS_ACTION_ALWAYS)
	menu:add(0, menuChapterNext, 3, '>')
		:setShowAsAction(J.android.view.MenuItem.SHOW_AS_ACTION_ALWAYS)

--[[ resize buttons ... might be easier to just use icons ...
	for i=0,menu:size()-1 do
		local item = menu:getItem(i)
		local s = J.android.text.SpannableString(item:getTitle())
		s:setSpan(J.android.text.style.RelativeSizeSpan(1.2), 0, s:length(), 0)
		item:setTitle(s)
	end
--]]

	menu:add(0, menuOpenBooks, 4, 'Books...')
	menu:add(0, menuOpenAbout, 5, 'About...')
	return true
end


local prevOnOptionsItemSelected = callbacks.onOptionsItemSelected
callbacks.onOptionsItemSelected = function(activity, item, ...)
	local itemID = item:getItemId()
	
	local function changeChapter(delta)
		local i = allChapters:find(currentChapter)
		if i then	-- won't find if we're not viewing a chapter (mabye grey out or hide icons?)
			local newChapter = allChapters[i+delta]
			if newChapter then
				showAndAddHistory{
					currentChapter = newChapter,
					currentBook = newChapter.book,
					showLevel = 3,
					show = show,
				}
			end
		end
	end

	if itemID == menuChapterPrev then
		changeChapter(-1)
	elseif itemID == menuChapterNext then
		changeChapter(1)
	elseif itemID == menuFontPlus then
		fontSize = fontSize + 2	-- upper bound?  exponential curve?
		refreshFontSize()
	elseif itemID == menuFontMinus then
		fontSize = math.max(4, fontSize - 2)
		refreshFontSize()
	elseif itemID == menuOpenBooks then
		-- TODO insert into a history table and then let back go back one history unit
		showAndAddHistory{
			showLevel = 1,
			show = show,
		}
	elseif itemID == menuOpenAbout then
		showAndAddHistory{
			show = showAbout,
		}
	end
	return prevOnOptionsItemSelected(activity, item, ...)
end

-- [[ hmm looks like you can't add an Intent or Action or whatever where 'back' works without multiple Activities
-- and you can't use multiple Activities without registering them all up front
-- and I can't do that because everything is script-driven at runtime
local prevOnBackPressed = callbacks.onBackPressed
callbacks.onBackPressed = function(activity, ...)
	if #backHistory <= 1 then
		return prevOnBackPressed(activity, ...)
	end
	backHistory:remove()
	showHistory(backHistory:last())
end
--]]

return function(methodName, activity, ...)
	return assert.index(callbacks, methodName)(activity, ...)
end
