Option Explicit
On Error Resume Next
'#┌──────────────────────────────────────
'#│  Phasmophobia Kurune Kokuri Texture Mod v1.0.0 (2022/02/20)
'#└──────────────────────────────────────
'#==============================================================================
Dim Conf
Set Conf = CreateObject("Scripting.Dictionary")
'#-- [ 基本設定 ] --------------------------------------------------------------
' PhasmophobiaアプリID
Call Conf.Add("APPID", "739630")
' Phasmophobiaレジストリキー
Call Conf.Add("REG_KEY", "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\Steam App " & Conf("APPID") & "\InstallLocation")
' Phasmophobiaマニフェストファイル
Call Conf.Add("ACF_FILE", "appmanifest_" & Conf("APPID") & ".acf")
' PhasmophobiaビルドID
Call Conf.Add("BUILDID", "8181468")
' Phasmophobiaアップデート履歴
' https://steamdb.info/app/739630/patchnotes/

' 日本語表示
If GetLocale() = 1041 Then Call Conf.Add("JA", true) Else Call Conf.Add("JA", false)

' メッセージ
Call Conf.Add("M_TITLE", "# Phasmophobia Kurune Kokuri Texture Mod v1.0.0")
If Conf("JA") Then Call Conf.Add("M_START", "何かキーを押すとインストールします") Else Call Conf.Add("M_EXIT", "Press any key to install")
If Conf("JA") Then Call Conf.Add("M_NOT_FOUND", "Phasmophobiaが見つかりませんでした。") Else Call Conf.Add("M_NOT_FOUND", "Phasmophobia not found")
If Conf("JA") Then Call Conf.Add("M_NOT_BUILDID", "対応バージョンではありません。") Else Call Conf.Add("M_NOT_BUILDID", "Not a supported version.")
If Conf("JA") Then Call Conf.Add("M_SKIP", "バックアップファイルが存在するのでスキップします。") Else Call Conf.Add("M_SKIP", "Backup file exists, so skip it.")
If Conf("JA") Then Call Conf.Add("M_ERROR", "エラーが発生しました。") Else Call Conf.Add("M_ERROR", "ERROR")
If Conf("JA") Then Call Conf.Add("M_ERR_NUM", "エラー番号：") Else Call Conf.Add("M_ERR_NUM", "ERR NUM:")
If Conf("JA") Then Call Conf.Add("M_ERR_DESC", "エラー内容：") Else Call Conf.Add("M_ERR_DESC", "ERR DESC:")
If Conf("JA") Then Call Conf.Add("M_EXIT", "何かキーを押すと終了します") Else Call Conf.Add("M_EXIT", "Press any key to exit")

' テクスチャーファイル
Dim a
push a, "sharedassets1.assets"
push a, "sharedassets2.assets"
Call Conf.Add("ASSETS", a)
Call Conf.Add("ASSETS_PATH", "")

'#------------------------------------------------------------------------------
Dim wsh, fso, inp
Set wsh = CreateObject("WScript.Shell")
Set fso = CreateObject("Scripting.FileSystemObject")

Call Main()
If Err.Number = -2147024894 Then
	WScript.Echo Conf("M_NOT_FOUND")
ElseIf Err.Number <> 0 Then
	WScript.Echo Conf("M_ERROR")
	WScript.Echo Conf("M_ERR_NUM") & Err.Number & " " & Conf("M_ERR_DESC") & Err.Description
End If

WScript.Echo vbLf & Conf("M_EXIT")
inp = WScript.StdIn.ReadLine

'#=============================================================================#
'#                               [ メイン関数 ]                                #
'#=============================================================================#
Function Main()
	'---------------------------------------------------------------------------
	' CSCRIPT.EXE で無い場合に切り替える

	Dim strPath, strTarget, strMyPath, strParam, j
	strPath   = WScript.FullName ' フルパス
	strTarget = Right( strPath, 11 )
	strTarget = Ucase( strTarget )

	if strTarget <> "CSCRIPT.EXE" then

		' 自分自身ののフルパス
		strMyPath = WScript.ScriptFullName
		strParam  = " "

		' 引数を全て読みだして、スペースが含まれていた場合は再度引き渡す為に " で囲み直しています
		For j = 0 to Wscript.Arguments.Count - 1
			If instr(Wscript.Arguments(j), " ") < 1 Then
				strParam = strParam & Wscript.Arguments(j) & " "
			Else
				strParam = strParam & """" & Wscript.Arguments(j) & """ "
			End If
		Next

		' CSCRIPT.EXE に引き継いで終了
		Call wsh.Run( "cscript.exe //nologo """ & strMyPath & """" & strParam, 1 )
		WScript.Quit

	end if
	'---------------------------------------------------------------------------
	' 処理開始

	WScript.Echo "#-------------------------------------------------------------------------------"
	WScript.Echo Conf("M_TITLE")
	WScript.Echo "#-------------------------------------------------------------------------------"

	WScript.Echo vbLf & Conf("M_START")
	inp = WScript.StdIn.ReadLine

	Call Conf.Add("DATA_PATH", wsh.RegRead(Conf("REG_KEY")) & "\Phasmophobia_Data\")

	' マニフェストを読む
	Dim sr, re, m
	Set sr = CreateObject("ADODB.Stream")
	sr.type = 2: sr.charset = "UTF-8"
	sr.Open
	sr.LoadFromFile Conf("DATA_PATH") & "..\..\..\" & Conf("ACF_FILE")
	Set re = New RegExp' 正規表現
	re.Pattern = "\t*""(buildid)""\t+""(.+)""": re.Global = True
	Do While sr.EOS = False
		Set m = re.Execute(sr.ReadText(-2))
		If m.Count > 0 Then 
			If m(0).SubMatches(1) <> Conf("BUILDID") Then
				WScript.Echo Conf("M_NOT_BUILDID")
				Exit Function
			End If
			Exit Do
		End If
	Loop
	sr.Close
	If Not sr Is Nothing Then Set sr = Nothing


	Dim f
	For Each f In Conf("ASSETS")

		' バックアップがある場合はスキップ
		If fso.FileExists(Conf("DATA_PATH") & f & "." & Conf("BUILDID") & ".org") Then
			WScript.Echo Conf("M_SKIP")
			WScript.Echo "(" & f & "." & Conf("BUILDID") & ".org)"
		Else
			fso.MoveFile Conf("DATA_PATH") & f, Conf("DATA_PATH") & f & "." & Conf("BUILDID") & ".org"
			WScript.Echo f & " -> " & f & "." & Conf("BUILDID") & ".org"
			fso.CopyFile Conf("ASSETS_PATH") & f, Conf("DATA_PATH") & f, False
			WScript.Echo f & " -> replaced"
		End If
	Next 

	'---------------------------------------------------------------------------
	Main = True
'#------------------------------------------------------------------------------
End Function

Sub push(ByRef arr, ByVal elm)
	Dim i, tmp: i = 0
	If IsArray(arr) Then
		For Each tmp In arr
			i = 1
			Exit For
		Next
		If i=1 Then Redim Preserve arr(Ubound(arr)+1) Else Redim arr(0)
	Else
		arr = Array(0)
	End If
	If IsObject(elm) Then Set arr(Ubound(arr)) = elm Else arr(Ubound(arr)) = elm
End Sub

