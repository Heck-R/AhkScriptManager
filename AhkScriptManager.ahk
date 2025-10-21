#Requires AutoHotkey v1

#SingleInstance Force

;-------------------------------------------------------

DetectHiddenWindows On
SetTitleMatchMode RegEx

;-------------------------------------------------------
; Settings

; List and possibly run scripts from under the "runnableScriptsRoot" (see "options" section). Finds scripts on the following formatted paths: "<categoryFolder>\scriptName.ahk" and "<categoryFolder>\scriptName\scriptName.ahk"
Hotkey +^0, runAnyScriptWindow
; Root folder to search for runnable scripts (see "runAnyScriptWindow"). Relative path can be defined by starting with ".\"
runnableScriptsRootPath := ".\..\..\"

; The script management hotkeys work even when this script is paused / suspended
Hotkey #y, reloadScripts
Hotkey #s, suspendScripts
Hotkey #Esc, exitScripts

;---------------------------------------------------------------------------------------------
;---------------------------------------------------------------------------------------------
;---------------------------------------------------------------------------------------------

reloadScripts() {
	Suspend permit

	WinGet, AHKWindows, List, .ahk - AutoHotkey,, %A_ScriptName%
	Loop %AHKWindows% {
		currID := AHKWindows%A_Index%
		PostMessage, 0x111, 65303,,, ahk_id %currID% ;Reload
	}
}

suspendScripts() {
	Suspend permit

	WinGet, AHKWindows, List, .ahk - AutoHotkey,, %A_ScriptName%
	Loop %AHKWindows% {
		currID := AHKWindows%A_Index%
		PostMessage, 0x111, 65305,,, ahk_id %currID% ;Suspend
		PostMessage, 0x111, 65306,,, ahk_id %currID% ;Pause
	}
}

exitScripts() {
	Suspend permit

	WinGet, AHKWindows, List, .ahk - AutoHotkey,, %A_ScriptName%
	Loop %AHKWindows% {
		currID := AHKWindows%A_Index%
		WinClose ahk_id %currID% ;Exit
	}
}

;---------------------------------------------------------------------------------------------
;---------------------------------------------------------------------------------------------
;---------------------------------------------------------------------------------------------

runAnyScriptWindow() {
	global iniFile ;Expected to be pre-set
	global runnableScriptsRootPath ;Set at the beginning of the script
	global categoryFolders ;Global value to set here
	global categoryFoldersContents ;Global value to set here

	runnableScriptsRootPath=%A_ScriptDir%\

	runnableScriptsRootPath := regexreplace(runnableScriptsRootPath, "^\.(\\|/)", A_ScriptDir)

	categoryFoldersContents:=Object()
	categoryFolders := ""

	Loop Files, %runnableScriptsRootPath%\*, D
	{
		currFolder:=A_LoopFileName
		filePaths:=[]
		fileNames:=""

		Loop Files, %runnableScriptsRootPath%\%currFolder%\*, DF
		{
			if(A_LoopFileExt == "ahk"){
				filePaths.Push(A_LoopFileName)
				fileNames=%fileNames%|%A_LoopFileName%
			} else{
				folderedFile=%A_LoopFileName%\%A_LoopFileName%.ahk
				folderedFilePath=%runnableScriptsRootPath%\%currFolder%\%folderedFile%
				if(FileExist(folderedFilePath)){
					filePaths.Push(folderedFile)
					fileNames=%fileNames%|%A_LoopFileName%.ahk
				}
			}
		}

		if(0<strlen(fileNames)) {
			categoryFoldersContents[currFolder]:=Object()
			categoryFoldersContents[currFolder]["fileNames"]:=fileNames
			categoryFoldersContents[currFolder]["filePaths"]:=filePaths
			if(categoryFolders!="")
				categoryFolders.="|"
			categoryFolders.=currFolder
		}
	}

	createRunAnyScriptWindow()
}

;------------------------------------------------

createRunAnyScriptWindow() {
	global categoryFolders ;Set in runAnyScriptWindow
	global categoryFolderChoice ;Global value to set by GUI created here
	global categoryFileChoice ;Global value to set by GUI created here

	Gui Destroy

	Gui Add, DropDownList, gSetFileList vcategoryFolderChoice x24 y12 w128,%categoryFolders%
	Gui Add, DropDownList, vcategoryFileChoice x24 y42 w128 AltSubmit

	Gui Add, Button, x48 y75 w80 h23, &OK

	Gui Show, w177 h106, RunAnyScript
}

;------------------------------------------------

SetFileList() {
	global categoryFoldersContents ;Set in runAnyScriptWindow
	global categoryFolderChoice ;Set in createRunAnyScriptWindow
	global categoryFileChoice ;Set in createRunAnyScriptWindow

	Gui Submit, NoHide
	fold:=categoryFoldersContents[categoryFolderChoice]["fileNames"]
	GuiControl,, categoryFileChoice, %fold%
}

;------------------------------------------------

ButtonOK() {
	global runnableScriptsRootPath ;Set in runAnyScriptWindow
	global categoryFoldersContents ;Set in runAnyScriptWindow
	global categoryFolderChoice ;Set in createRunAnyScriptWindow
	global categoryFileChoice ;Set in createRunAnyScriptWindow

	Gui submit
	filePath := categoryFoldersContents[categoryFolderChoice]["filePaths"][categoryFileChoice]
	Run %runnableScriptsRootPath%\%categoryFolderChoice%\%filePath%

	Gui Destroy
}

GuiEscape() {
	Gui Destroy
}

GuiClose() {
	Gui Destroy
}
