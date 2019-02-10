.386
MODEL FLAT, STDCALL
LOCALS
JUMPS

UNICODE=0

INCLUDE	W32.INC
INCLUDE	WIN.INC

EXTRN	_wsprintfA			: PROC
EXTRN	SetSysColors	: PROC
EXTRN	SetWindowLongA	: PROC
EXTRN	CallWindowProcA	: PROC

.DATA

szAppName		db MAX_PATH+10 dup (?)
szCurFile		db MAX_PATH dup (?)
szSaveMsg		db MAX_PATH+70 dup (?)
szUntitled		db "Untitled",0
szAppTitle		db " - NfoView v1.11 by HaRdLoCk",0
szWindowName	db "NfoView v1.11",0
szMenuName		db "MAINMENU",0
szClassName		db "NfoViewClass",0
szScreenError	db "Hey... this is made for 786x1024 resolution... ",13,10
				db "you didn't read the readme eh?",0
szModuleName	db MAX_PATH+3 dup (?)
		
stWinClass 		WNDCLASSEX 		<>
stMessage		MSG				<>
stSystray		NOTIFYICONDATA	<>

dwBuffSize		dd 8
dwBuffSize2		dd 16*4

.DATA?

hApp			dd ?
hIcon			dd ?
hFile			dd ?
hAccel			dd ?
hRegKey			dd ?
pszCmdLine		dd ?
dwCmdLen		dd ?
hButton			dd ?
bSystray		dd ?
bBigFont		dd ?
dwDisposition	dd ?

.CODE

Start:
	
		call	GetModuleHandleA, NULL
		mov		hApp, eax
		call	GetCommandLine
		call	GetCmdLineArgs
		mov		pszCmdLine, eax
		call	GetFileTitleA, pszCmdLine, offset szAppName, MAX_PATH
		.IF		byte ptr [szAppName]==0
			call	lstrcpy, offset szAppName, offset szUntitled
		.ENDIF
		call	lstrlen, offset szAppName
    	.IF		eax>50
    		mov 	dword ptr [szAppName+47], 0002E2E2Eh
    	.ENDIF
		call	lstrcat, offset szAppName, offset szAppTitle
		call	InitRegValues		
		call	WinMain, hApp, NULL, pszCmdLine, SW_SHOWDEFAULT
		call	ExitProcess, NULL

WinMain	PROC, hDlg:HWND, hPrevInst:HINSTANCE, CmdLine:LPSTR, CmdShow:DWORD 

	mov		stWinClass.wc_cbSize, size WNDCLASSEX
	mov		stWinClass.wc_style, NULL	
	mov		stWinClass.wc_lpfnWndProc, offset WndProc
	mov		stWinClass.wc_cbClsExtra, NULL
	mov		stWinClass.wc_cbWndExtra, NULL	
	push	hApp
	pop		stWinClass.wc_hInstance
	call	LoadIcon, hApp, ID_ICON
	mov		hIcon, eax
	mov		stWinClass.wc_hIcon, eax	
	call	LoadCursor, NULL, IDC_ARROW
	mov		stWinClass.wc_hCursor, eax
	call	CreateSolidBrush, rgbWndBack
	mov		stWinClass.wc_hbrBackground, eax
	mov		stWinClass.wc_lpszClassName, offset szClassName
	call	RegisterClassEx, offset stWinClass
	.IF		bSystray==TRUE
		mov		eax, WS_EX_TOOLWINDOW
	.ELSE
		mov		eax, NULL
	.ENDIF
	call	CreateWindowEx, eax, offset szClassName, offset szWindowName, \
			WS_POPUPWINDOW, CW_USEDEFAULT, CW_USEDEFAULT, CW_USEDEFAULT, CW_USEDEFAULT, \
			NULL, NULL, hApp, NULL
	mov		hDlg, eax
	;call	ShowWindow, hDlg, SW_NORMAL
	;call 	UpdateWindow, hDlg	
    .WHILE TRUE
        call	GetMessage, offset stMessage, NULL, 0, 0 
        .BREAK .IF eax==FALSE
			call 	TranslateMessage, offset stMessage
			call	DispatchMessage, offset stMessage
    .ENDW
    mov     eax, stMessage.ms_wParam 
    ret
    
WinMain	ENDP

GetCmdLineArgs	PROC

	.IF		byte ptr [eax]=='"'
		inc		eax
		.WHILE	!byte ptr [eax]=='"'
			inc		eax
		.ENDW
		add		eax, 2
	.ELSE
		mov		pszCmdLine, eax
		call	GetModuleFileNameA, NULL, offset szModuleName, MAX_PATH+3
		lea		esi, szModuleName
		mov		edi, pszCmdLine
		call	lstrlen, pszCmdLine
		mov		ecx, eax
		repz	cmpsb
		xchg	eax, edi
	.ENDIF
	ret
	
GetCmdLineArgs	ENDP	

InitRegValues	PROC

	call	RegCreateKeyExA, HKEY_CURRENT_USER, offset szSubKey, NULL, NULL, \
			NULL, KEY_WRITE+KEY_READ, NULL, offset hRegKey, offset dwDisposition
	.IF		dwDisposition==REG_CREATED_NEW_KEY
		call	RegSetValueExA, hRegKey, offset szRgbEditBack, NULL, REG_DWORD, offset dwEditBack, 4
		call	RegSetValueExA, hRegKey, offset szRgbEditText, NULL, REG_DWORD, offset dwEditText, 4
		call	RegSetValueExA, hRegKey, offset szRgbTitleBack, NULL, REG_DWORD, offset dwEditBack, 4
		call	RegSetValueExA, hRegKey, offset szRgbTitleText, NULL, REG_DWORD, offset dwEditText, 4
		call	RegSetValueExA, hRegKey, offset szRgbWndBack, NULL, REG_DWORD, offset dwWndBack, 4
		call	RegSetValueExA, hRegKey, offset szTrayIcon, NULL, REG_DWORD, offset dwFalse, 4
		call	RegSetValueExA, hRegKey, offset szBigFont, NULL, REG_DWORD, offset dwFalse, 4
		mov		rgbTitleText, 0FFFFFFh
		mov		rgbEditText, 0FFFFFFh
	.ELSE
		call	RegQueryValueExA, hRegKey, offset szRgbEditBack, NULL, NULL, offset rgbEditBack, offset dwBuffSize
		call	RegQueryValueExA, hRegKey, offset szRgbEditText, NULL, NULL, offset rgbEditText, offset dwBuffSize
		call	RegQueryValueExA, hRegKey, offset szRgbTitleBack, NULL, NULL, offset rgbTitleBack, offset dwBuffSize
		call	RegQueryValueExA, hRegKey, offset szRgbTitleText, NULL, NULL, offset rgbTitleText, offset dwBuffSize
		call	RegQueryValueExA, hRegKey, offset szRgbWndBack, NULL, NULL, offset rgbWndBack, offset dwBuffSize
		call	RegQueryValueExA, hRegKey, offset szTrayIcon, NULL, NULL, offset bSystray, offset dwBuffSize
		call	RegQueryValueExA, hRegKey, offset szBigFont, NULL, NULL, offset bBigFont, offset dwBuffSize
		call	RegQueryValueExA, hRegKey, offset szCustColors, NULL, NULL, offset stCustColors, offset dwBuffSize2
	.ENDIF
	call	RegCloseKey, hRegKey
	ret
	
InitRegValues	ENDP

.DATA?

dwFileSize		dd ?
pszFileText		dd ?

.CODE

	
LoadFile	PROC, hWndEdit:DWORD, pszFileName:LPSTR

   	call	CreateFile, pszFileName, GENERIC_READ, FILE_SHARE_READ+FILE_SHARE_WRITE, \
   			NULL, OPEN_EXISTING, NULL, NULL
   	mov		hFile, eax
	.IF		!hFile==INVALID_HANDLE_VALUE
      	call	GetFileSize, hFile, NULL
      	mov		dwFileSize, eax
      	inc		dwFileSize
      	.IF		!dwFileSize==INVALID_HANDLE_VALUE
         	call	GlobalAlloc, GMEM_FIXED+GMEM_ZEROINIT+GMEM_DDESHARE, dwFileSize
			mov		pszFileText, eax
         	.IF		!pszFileText==NULL
           	 	call	ReadFile, hFile, pszFileText, dwFileSize, offset dwBuff, NULL
           	 	dec		dwFileSize
COMMENT ~           	 	
           	 	mov	esi, pszFileText
           	 	mov	edx, esi
           	 	add	esi, dwFileSize
           	 	.WHILE	!edx==esi
           	 		.IF	byte ptr [edx]==0Dh
           	 			mov byte ptr [edx], 0Ah
           	 		.ENDIF
           	 		inc edx
           	 	.ENDW
~           	 	
               	call	SetWindowText, hWndEdit, pszFileText
               	call	SetFocus, hWndEdit
            .ENDIF
            call	GlobalFree, pszFileText
        .ENDIF
	.ENDIF
	ret
	
LoadFile	ENDP

.DATA?

dwBuff			dd ?
dwTextLength	dd ?
pszText_			dd ?

.CODE

SaveFile	PROC, hWndEdit:HWND, pszFileName:LPSTR

	call	CreateFile, pszFileName, GENERIC_WRITE+GENERIC_READ, FILE_SHARE_READ+FILE_SHARE_WRITE, \
			NULL, CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, NULL
	mov		hFile, eax
   	.IF		!hFile==INVALID_HANDLE_VALUE
	    call	GetWindowTextLengthA, hWndEdit
	    mov		dwTextLength, eax
	    inc		dwTextLength
	    .IF		dwTextLength>0
	        call	GlobalAlloc, GMEM_FIXED+GMEM_ZEROINIT, dwTextLength
	        mov		pszText_, eax
	        .IF		!pszText_==NULL	        
				call	GetWindowTextA, hWndEdit, pszText_, dwTextLength
				dec		dwTextLength
	            call	WriteFile, hFile, pszText_, dwTextLength, offset dwBuff, NULL
	            call	GlobalFree, pszText_
			.ENDIF
		.ENDIF
	.ELSE
		call	MessageBoxA, hDlg, pszFileName, NULL, MB_OK	
   	.ENDIF
    call	CloseHandle, hFile
    call	SendMessage, hEdit, EM_SETMODIFY, FALSE, NULL    
	ret
	
SaveFile	ENDP

.DATA

szFileFilter	db "Nfo Files (*.nfo)",0,"*.nfo",0,"All Files (*.*)",0,"*.*",0,0
szFileName		db MAX_PATH	dup (?)
szDefExt		db "nfo",0

.CODE

DoFileOpenSave	PROC, hDlg:DWORD, bSave:BOOL

   	call	RtlZeroMemory, offset stOpenFile, size OPENFILENAME
	mov		stOpenFile.on_lStructSize, size OPENFILENAME
	push	hDlg
	pop		stOpenFile.on_hwndOwner
	mov		stOpenFile.on_lpstrFile, offset szFileName
	mov		stOpenFile.on_lpstrFilter, offset szFileFilter
	call	GetFileTitleA, offset szCurFile, offset szFileName, MAX_PATH
	mov		stOpenFile.on_nMaxFile, MAX_PATH
	mov		stOpenFile.on_lpstrDefExt, offset szDefExt
   	.IF		bSave==TRUE
		mov		stOpenFile.on_Flags, OFN_EXPLORER+OFN_PATHMUSTEXIST+OFN_OVERWRITEPROMPT+OFN_HIDEREADONLY
        call	GetSaveFileName, offset stOpenFile
        .IF		!eax==0
        	call	SaveFile, hEdit, offset szFileName
        .ENDIF
	.ELSE
	     mov	stOpenFile.on_Flags, OFN_EXPLORER+OFN_FILEMUSTEXIST+OFN_HIDEREADONLY
	     mov	stOpenFile.on_lpstrInitialDir, NULL
	     call	GetOpenFileName, offset stOpenFile
	     .IF	!eax==0
	     	call	LoadFile, hEdit, offset szFileName
	     .ENDIF
	.ENDIF
	.IF		!byte ptr [szFileName]==0
		call	lstrcpy, offset szCurFile, offset szFileName
		call	GetFileTitleA, offset szFileName, offset szAppName, MAX_PATH
		call	lstrlen, offset szAppName
    	.IF		eax>50
    		mov 	dword ptr [szAppName+47], 0002E2E2Eh
    	.ENDIF		
		call	lstrcat, offset szAppName, offset szAppTitle
		call	InvalidateRect, hDlg, NULL, TRUE
	.ENDIF
	call	RtlZeroMemory, offset szFileName, MAX_PATH	
	ret
	
DoFileOpenSave	ENDP

.DATA

szEditClass		db "edit",0
szButClass		db "button",0
szFontName		db "Tarminal",0
szAboutApp		db "NfoView",0
szChangeText	db "The file %s has changed"
				db 13,10,13,10,"Want to save it now?",0
szBitmap		db "IDB_BITMAP",0
szAbout			db "NfoView v1.11 by HaRdLoCk [BLZ/OXY]",13,10,"Coded in 32bit Assembly in TASM v5.0",0

szMenuOpen		db "Open",0
szMenuNew		db "New",0
szMenuSave		db "Save",0
szMenuSaveAs	db "Save As",0
szMenuOptions	db "Options",0
szMenuAbout		db "About",0
szMenuExit		db "Exit",0

stRect			RECT			<>
stLblRect		RECT			<>
stPaint			PAINTSTRUCT		<>
stBitmap		BITMAP			<>
stButton		WNDCLASS		<>
stPoint			POINT			<>
stColors		CHOOSECOLOR		<>
stOpenFile   	OPENFILENAME 	<>
stCustColors	dd 16 dup (?)
	
szSubKey		db "Software\NfoView",0

szRgbEditBack	db "RgbEditBack",0
szRgbEditText	db "RgbEditText",0
szRgbTitleBack	db "RgbTitleBack",0
szRgbTitleText	db "RgbTitleText",0
szRgbWndBack	db "RgbWndBack",0
szTrayIcon		db "TrayIconEnable",0
szCustColors	db "CustomColors",0
szBigFont		db "BigFontEnable",0
szWindowStyle	dd WS_EX_TOOLWINDOW

dwEditBack		dd 000000000h
dwEditText		dd 000FFFFFFh
dwTitleBack		dd 000000000h
dwTitleText		dd 000FFFFFFh
dwWndBack		dd 000000000h

.DATA?

rgbEditBack		dd ?
rgbEditText		dd ?
rgbTitleText	dd ?
rgbTitleBack	dd ?
rgbWndBack		dd ?

.DATA?

hEdit			dd ?
hFont			dd ?
hMenu			dd ?
hWinDc			dd ?
hBmp			dd ?
hBut			dd ?
hPopMenu		dd ?
hSubMenu		dd ?
dwOldWndProc	dd ?

.CODE

WndProc	PROC, hDlg:HWND, uMsg:UINT, wPara:WPARAM, lPara:LPARAM

	.IF		uMsg==WM_CREATE	
		call	SetSysColors, 1, COLOR_SCROLLBAR, 0FFEECCh
       	call	MoveWindow, hDlg, 0, 0, 504, 640, TRUE
		call	CenterWindowA, hDlg	
		call	LoadBitmap, hApp, offset szBitmap
    	mov		hBmp, eax
    	mov		eax, stRect.rc_right
    	sub		eax, 22
		call	CreateWindowEx, NULL, offset szButClass, NULL, WS_CHILD+WS_VISIBLE+BS_BITMAP,\ 
                eax, 4, 16, 14, hDlg, EXIT, hApp, NULL
        mov		hBut, eax
        call	SendMessage, eax, BM_SETIMAGE, IMAGE_BITMAP, hBmp
		call	SetWindowLongA, hBut, GWL_WNDPROC, offset EditWndProc		
		mov 	dwOldWndProc, eax        
       	call	CreateFontA, 9, 0, 0, 0, FW_NORMAL, FALSE, FALSE, FALSE, DEFAULT_CHARSET, \
        		OUT_DEFAULT_PRECIS, CLIP_DEFAULT_PRECIS, DEFAULT_QUALITY, DEFAULT_PITCH, offset szFontName
       	mov		hFont, eax	
		call	CreateWindowEx, NULL, offset szEditClass, NULL,\ 
        		WS_CHILD+WS_VISIBLE+ES_LEFT+ES_AUTOHSCROLL+WS_VSCROLL+ES_MULTILINE+ES_WANTRETURN+ES_OEMCONVERT,\ 
        		0, 0, 0, 0, hDlg, TEXT, hApp, NULL
		mov		hEdit, eax		
       	call	SendMessageA, hEdit, WM_SETFONT, hFont, TRUE		
		.IF		byte ptr [szAppName]>60h && byte ptr [szAppName]<7Bh
			sub		byte ptr [szAppName], 20h
		.ENDIF		
        call	LoadFile, hEdit, pszCmdLine
        call	lstrcpy, offset szCurFile, pszCmdLine
        call	SetFocus, hEdit
		call	CreatePopupMenu
		mov		hMenu, eax
		call	AppendMenuA, hMenu, MF_STRING, OPEN, offset szMenuOpen
		call	AppendMenuA, hMenu, MF_STRING, NEW, offset szMenuNew
		call	AppendMenuA, hMenu, MF_STRING, SAVE, offset szMenuSave
		call	AppendMenuA, hMenu, MF_STRING, SAVEAS, offset szMenuSaveAs
		call	AppendMenuA, hMenu, MF_SEPARATOR, NULL, NULL
		call	AppendMenuA, hMenu, MF_STRING, OPTIONS, offset szMenuOptions
		call	AppendMenuA, hMenu, MF_SEPARATOR, NULL, NULL
		call	AppendMenuA, hMenu, MF_STRING, EXIT, offset szMenuExit		
		.IF		bSystray==TRUE
			call	SetSysTrayIcon
		.ENDIF
		call	DragAcceptFiles, hDlg, TRUE
		call	ShowWindow, hDlg, SW_NORMAL
    	call 	UpdateWindow, hDlg    	
	.ELSEIF	uMsg==WM_PAINT
		call	BeginPaint, hDlg, offset stPaint
		mov		hWinDc, eax
		call	SelectObject, hWinDc, hFont
		call	SetTextColor, hWinDC, rgbTitleText
		call	SetBkColor, hWinDC, rgbTitleBack
		call	lstrlen, offset szAppName
		call	TextOut, hWinDC, 6, 7, offset szAppName, eax
		call	ReleaseDC, hDlg, hWinDc
		call	EndPaint, hDlg, offset stPaint
	.ELSEIF	uMsg==WM_ERASEBKGND
		call	GetClientRect, hDlg, offset stRect
		call	CreateSolidBrush, rgbWndBack
		call	FillRect, wPara, offset stRect, eax
	.ELSEIF	uMsg==WM_LBUTTONDOWN
			call	PostMessageA, hDlg, WM_NCLBUTTONDOWN, HTCAPTION, lPara
	.ELSEIF	uMsg==WM_RBUTTONDOWN
		call	GetCursorPos, offset stPoint
		call	TrackPopupMenu, hMenu, TPM_LEFTALIGN+TPM_RIGHTBUTTON, \
				stPoint.pt_x, stPoint.pt_y, NULL, hDlg, NULL
	.ELSEIF	uMsg==WM_CTLCOLOREDIT
		call	SetTextColor, wPara, rgbEditText
		call	SetBkColor, wPara, rgbEditBack
		call	CreateSolidBrush, rgbEditBack
	.ELSEIF	uMsg==WM_SIZE
		.IF		!wPara==SIZE_MINIMIZED
	    	call	GetClientRect, hDlg, offset stRect
	    	mov		eax, stRect.rc_right
	    	sub 	eax, 12
	    	mov		edx, stRect.rc_bottom
	    	sub		edx, 28
	        call	MoveWindow, hEdit, 6, 22, eax, edx, TRUE
		.ENDIF
	.ELSEIF	uMsg==WM_SHELLNOTIFY
		.IF		wPara==SYSTRAY
			.IF		lPara==WM_RBUTTONDOWN
				call	SetForegroundWindow, hDlg
				call 	GetCursorPos, offset stPoint
				call 	TrackPopupMenu, hPopMenu, TPM_RIGHTALIGN+TPM_RIGHTBUTTON, \
						stPoint.pt_x, stPoint.pt_y, NULL, hDlg, NULL
				call	SendMessage, hDlg, WM_USER, NULL, NULL
				call	SetForegroundWindow, hDlg
			.ELSEIF lPara==WM_LBUTTONDBLCLK || lPara==WM_LBUTTONUP
				call	SetForegroundWindow, hDlg
				call	SetFocus, hEdit
			.ENDIF
		.ENDIF				
	.ELSEIF	uMsg==WM_COMMAND
		.IF		wPara==EXIT
			call	SendMessage, hDlg, WM_CLOSE, NULL, NULL
		.ELSEIF	wPara==OPEN
			call	DoFileOpenSave, hDlg, FALSE
		.ELSEIF	wPara==NEW
			call	CheckIfFileChanged
			.IF	!eax==IDCANCEL
				call	SendMessage, hEdit, WM_SETTEXT, NULL, NULL
				call	lstrcpy, offset szAppName, offset szUntitled
				call	lstrcat, offset szAppName, offset szAppTitle
				call	InvalidateRect, hDlg, NULL, TRUE
			.ENDIF
			call	SetFocus, hEdit
		.ELSEIF	wPara==SAVE
        	.IF		byte ptr [szAppName]=="U"
        		call	DoFileOpenSave, hDlg, TRUE
        	.ELSE
            	call	SaveFile, hEdit, offset szCurFile
			.ENDIF
		.ELSEIF	wPara==SAVEAS
			call	DoFileOpenSave, hDlg, TRUE
		.ELSEIF	wPara==OPTIONS
			push	bSystray
			call	DialogBoxParamA, hApp, DIALOG, hDlg, offset DialogProc, NULL
			pop		eax
			.IF		bSystray==TRUE && eax==FALSE
				call	SetSysTrayIcon
			.ELSEIF	bSystray==FALSE && eax==TRUE
				call 	Shell_NotifyIcon, NIM_DELETE, offset stSystray
			.ENDIF
			call	InvalidateRect, hDlg, NULL, TRUE
		.ENDIF
	.ELSEIF	uMsg==WM_CLOSE
		call	CheckIfFileChanged
		.IF		!eax==IDCANCEL
			call	SendMessage, hDlg, WM_DESTROY, NULL, NULL
			.IF		bSystray==TRUE
				call 	Shell_NotifyIcon, NIM_DELETE, offset stSystray
			.ENDIF
		.ENDIF
	.ELSEIF	uMsg==WM_DROPFILES
		call	DragQueryFile, wPara, 0, offset szDropFile, MAX_PATH
		call	CheckIfFileChanged
		.IF	!eax==IDCANCEL
			call	LoadFile, hEdit, offset szDropFile
			call	GetFileTitleA, offset szDropFile, offset szCurFile, MAX_PATH
    		call	lstrcpy, offset szAppName, offset szCurFile
			call	lstrcat, offset szAppName, offset szAppTitle
			.IF		byte ptr [szAppName]>60h && byte ptr [szAppName]<7Bh
				sub		byte ptr [szAppName], 20h
			.ENDIF
			call	InvalidateRect, hDlg, NULL, TRUE
		.ENDIF
		call	SetFocus, hEdit
		call	DragFinish, wPara
    .ELSEIF	uMsg==WM_DESTROY
        call	PostQuitMessage, NULL
	.ELSE
        call	DefWindowProc, hDlg, uMsg, wPara, lPara
   	.ENDIF
   	ret

WndProc	ENDP

EditWndProc	PROC	hWndEdit:DWORD, uMsg:DWORD, wPara:DWORD, lPara:DWORD
	
	.IF	uMsg==WM_CHAR
		call	MessageBoxA, hWndEdit, offset szWindowName, NULL, MB_OK
	.ELSE
		call	CallWindowProcA, dwOldWndProc, hWndEdit, uMsg, wPara, lPara
	.ENDIF
	ret
	
EditWndProc	ENDP

.DATA

szDropFile	db MAX_PATH dup (?)

.CODE

CheckIfFileChanged	Proc

	call	SendMessage, hEdit, EM_GETMODIFY, NULL, NULL
	.IF		eax==TRUE
		.IF		byte ptr [szCurFile]==0
			call	_wsprintfA, offset szSaveMsg, offset szChangeText, offset szUntitled
		.ELSE
			call	_wsprintfA, offset szSaveMsg, offset szChangeText, offset szCurFile
		.ENDIF
		add		esp, 0Ch		
		call	MessageBoxA, hDlg, offset szSaveMsg, offset szAboutApp, MB_YESNOCANCEL+MB_ICONEXCLAMATION
		.IF		eax==IDYES
			.IF		byte ptr [szAppName]=="U"
				call	DoFileOpenSave, hEdit, TRUE
			.ELSE
				call	SaveFile, hEdit, offset szCurFile
			.ENDIF
		.ENDIF
	.ELSE
		mov		eax, IDNO
	.ENDIF
	ret
			
CheckIfFileChanged	ENDP

CenterWindowA	PROC, hDlg:HWND

.DATA

stDlgRect	RECT	<>
stDeskRect	RECT	<>

.CODE

LOCAL	DlgHight:DWORD
LOCAL	DlgWidth:DWORD
LOCAL	Dlg_X:DWORD
LOCAL	Dlg_Y:DWORD

	call	GetWindowRect, hDlg, offset stDlgRect
	call	GetDesktopWindow
	call	GetWindowRect, eax, offset stDeskRect
	mov		eax, stDlgRect.rc_bottom
	sub		eax, stDlgRect.rc_top
	mov		DlgHight, eax
	mov		eax, stDlgRect.rc_right
	sub		eax, stDlgRect.rc_left
	mov		DlgWidth, eax
	mov		eax, stDeskRect.rc_bottom
	sub		eax, DlgHight
	shr		eax, 1
	mov		Dlg_Y, eax
	mov		eax, stDeskRect.rc_right
	sub		eax, DlgWidth
	shr		eax, 1
	mov		Dlg_X, eax
	call	MoveWindow, hDlg, Dlg_X, Dlg_Y, DlgWidth, DlgHight, TRUE
	xor		eax, eax
	ret
	
CenterWindowA	ENDP

.DATA

dwTrue		dd 1
dwFalse		dd 0

NFOCOLOR	STRUCT

	EditBack	dd ?
	EditText	dd ?
	TitleBack	dd ?
	TitleText	dd ?
	WndBack		dd ?

NFOCOLOR	ENDS

stNfoColor	NFOCOLOR	<>

.CODE

DialogProc PROC, hWndDlg:DWORD, uMsg:DWORD, wPara:DWORD, lPara:DWORD

	.IF		uMsg==WM_CLOSE
		call	EnableMenuItem, hPopMenu, OPTIONS, MF_ENABLED
		call	EndDialog, hWndDlg, NULL
	.ELSEIF	uMsg==WM_INITDIALOG
		call	EnableMenuItem, hPopMenu, OPTIONS, MF_GRAYED
		mov		stColors.cc_lStructSize, size CHOOSECOLOR
		push	hWndDlg
		pop		stColors.cc_hwndOwner
		push	hApp
		pop		stColors.cc_hInstance
		mov		stColors.cc_flags, CC_FULLOPEN+CC_RGBINIT
		mov		stColors.cc_lpCustColors, offset stCustColors
		push	rgbEditBack
		pop		stNfoColor.EditBack		
		push	rgbEditText
		pop		stNfoColor.EditText
		push	rgbTitleBack
		pop		stNfoColor.TitleBack
		push	rgbTitleText
		pop		stNfoColor.TitleText
		push	rgbWndBack		
		pop		stNfoColor.WndBack
		.IF		bSystray==TRUE
			call	CheckDlgButton, hWndDlg, IDC_CHECK, TRUE
		.ENDIF
	.ELSEIF	uMsg==WM_CTLCOLORSTATIC
		call	ShowColorSelection, stNfoColor.EditText, IDC_STATIC_FONT, lPara, wPara, hWndDlg
		call	ShowColorSelection, stNfoColor.EditBack, IDC_STATIC_BACK, lPara, wPara, hWndDlg
		call	ShowColorSelection, stNfoColor.TitleText, IDC_STATIC_TITLE, lPara, wPara, hWndDlg
		call	ShowColorSelection, stNfoColor.TitleBack, IDC_STATIC_CAPTION, lPara, wPara, hWndDlg
		call	ShowColorSelection, stNfoColor.WndBack, IDC_STATIC_BORDER, lPara, wPara, hWndDlg
	.ELSEIF	uMsg==WM_COMMAND
		.IF	wPara==IDC_SAVE
			push	stNfoColor.EditBack
			pop		rgbEditBack
			push	stNfoColor.EditText
			pop		rgbEditText
			push	stNfoColor.TitleBack
			pop		rgbTitleBack
			push	stNfoColor.TitleText
			pop		rgbTitleText
			push	stNfoColor.WndBack
			pop		rgbWndBack
			call	RegCreateKeyExA, HKEY_CURRENT_USER, offset szSubKey, NULL, NULL, \
					NULL, KEY_WRITE+KEY_READ, NULL, offset hRegKey, NULL
			call	RegSetValueExA, hRegKey, offset szRgbEditBack, NULL, REG_DWORD, offset rgbEditBack, 4
			call	RegSetValueExA, hRegKey, offset szRgbEditText, NULL, REG_DWORD, offset rgbEditText, 4
			call	RegSetValueExA, hRegKey, offset szRgbTitleBack, NULL, REG_DWORD, offset rgbTitleBack, 4
			call	RegSetValueExA, hRegKey, offset szRgbTitleText, NULL, REG_DWORD, offset rgbTitleText, 4
			call	RegSetValueExA, hRegKey, offset szRgbWndBack, NULL, REG_DWORD, offset rgbWndBack, 4
			call	IsDlgButtonChecked, hDlg, IDC_CHECK
			.IF		eax==TRUE
				call	RegSetValueExA, hRegKey, offset szTrayIcon, NULL, REG_DWORD, offset dwTrue, 4
				mov		bSystray, TRUE
			.ELSE
				call	RegSetValueExA, hRegKey, offset szTrayIcon, NULL, REG_DWORD, offset dwFalse, 4
				mov		bSystray, FALSE
			.ENDIF
			call	RegSetValueExA, hRegKey, offset szCustColors, NULL, REG_BINARY, offset stCustColors, 16*4
			call	RegCloseKey, hRegKey
			call	SendMessage, hWndDlg, WM_CLOSE, NULL, NULL
		.ELSEIF	wPara==IDC_CANCEL
			call	SendMessage, hWndDlg, WM_CLOSE, NULL, NULL
		.ELSEIF	wPara==IDC_ABOUT
			call	MessageBoxA, hDlg, offset szAbout, offset szAboutApp, MB_OK+MB_ICONINFORMATION
		.ELSEIF	wPara==IDC_EDIT_BACK
			call	ChooseColorProc, rgbEditBack
			mov		stNfoColor.EditBack, eax
			call	InvalidateRect, hWndDlg, NULL, TRUE
		.ELSEIF	wPara==IDC_EDIT_TEXT
			call	ChooseColorProc, rgbEditText
			mov		stNfoColor.EditText, eax
			call	InvalidateRect, hWndDlg, NULL, TRUE
		.ELSEIF	wPara==IDC_TITLE_TEXT
			call	ChooseColorProc, rgbTitleText
			mov		stNfoColor.TitleText, eax
			call	InvalidateRect, hWndDlg, NULL, TRUE
		.ELSEIF	wPara==IDC_TITLE_BACK
			call	ChooseColorProc, rgbTitleBack
			mov		stNfoColor.TitleBack, eax
			call	InvalidateRect, hWndDlg, NULL, TRUE
		.ELSEIF	wPara==IDC_WND_BACK
			call	ChooseColorProc, rgbWndBack
			mov		stNfoColor.WndBack, eax
			call	InvalidateRect, hWndDlg, NULL, TRUE
		.ELSEIF	wPara==IDC_NFO
			call	MessageBoxA, hWndDlg, offset szNfoText, offset szAboutApp, MB_YESNO+MB_ICONQUESTION
			.IF		eax==IDYES
				call	RegCreateKeyExA, HKEY_CLASSES_ROOT, offset szSubKeyNfo, NULL, NULL, NULL, \
						KEY_WRITE, NULL, offset hRegKey, NULL
				call	RegSetValueExA, hRegKey, NULL, NULL, REG_SZ, offset szNfoFile, 7
				call	RegCloseKey, hRegKey
				call	GetModuleFileNameA, hApp, offset szModuleName, MAX_PATH
				call	RegCreateKeyExA, HKEY_CLASSES_ROOT, offset szModuleName, NULL, NULL, NULL, \
						KEY_WRITE, NULL, offset hRegKey, NULL
				call	lstrlen, offset szModuleName
				call	RegSetValueExA, hRegKey, NULL, NULL, REG_SZ, offset szModuleName, eax
				call	lstrcat, offset szModuleName, offset szCmdLine
				call	RegCreateKeyExA, HKEY_CLASSES_ROOT, offset szKeyNfo, NULL, NULL, NULL, \
						KEY_WRITE, NULL, offset hRegKey, NULL
				call	lstrlen, offset szModuleName
				call	RegSetValueExA, hRegKey, NULL, NULL, REG_SZ, offset szModuleName, eax
				call	RegCloseKey, hRegKey				
				call	RegCloseKey, hRegKey
			.ENDIF
		.ELSEIF	wPara==IDC_DIZ
			call	MessageBoxA, hWndDlg, offset szDizText, offset szAboutApp, MB_YESNO+MB_ICONQUESTION
			.IF		eax==IDYES
				call	RegCreateKeyExA, HKEY_CLASSES_ROOT, offset szSubKeyDiz, NULL, NULL, NULL, \
						KEY_WRITE, NULL, offset hRegKey, NULL
				call	RegSetValueExA, hRegKey, NULL, NULL, REG_SZ, offset szNfoFile, 7
				call	RegCloseKey, hRegKey
			.ENDIF
		.ENDIF
	.ENDIF
	xor eax,eax
	ret
	
DialogProc ENDP

.DATA

szNfoText		db "This will assoziate .nfo files with NfoView",13,10
				db "Would you like to do that now?",0
szDizText		db "This will assoziate .diz files with NfoView",13,10
				db "Would you like to do that now?",0
szSubKeyNfo		db ".nfo",0
szSubKeyDiz		db ".diz",0
szNfoFile		db "NfoFile",0
szNfoFileIcon	db "NfoFile\DefaultIcon",0
szKeyNfo		db "NfoFile\Shell\Open\Command",0
szCmdLine		db " %1",0
szCurDir		db MAX_PATH	dup (?)

.CODE

ShowColorSelection	PROC	rgbColor:DWORD, IdName:DWORD, lPara:DWORD, wPara:DWORD, hWndDlg:DWORD

	call	GetDlgItem, hWndDlg, IdName
	.IF		lPara==eax
		call	GetWindowRect, eax, offset stRect
		call	CreateSolidBrush, rgbColor
		push	eax
		call	CreateRectRgn, 0, 0, stRect.rc_right, stRect.rc_bottom
		pop		edx
		call	FillRgn, wPara, eax, edx
	.ENDIF
	ret

ShowColorSelection	ENDP

ChooseColorProc	PROC	dwInitialColor:DWORD

	push	dwInitialColor
	pop		stColors.cc_rgbResult
	call	ChooseColorA, offset stColors
	mov		eax, stColors.cc_rgbResult
	ret

ChooseColorProc	ENDP

SetSysTrayIcon	PROC

	call	CreatePopupMenu
	mov		hPopMenu, eax
	call	AppendMenuA, hPopMenu, MF_STRING, OPTIONS, offset szMenuOptions
	call	AppendMenuA, hPopMenu, MF_SEPARATOR, NULL, NULL
	call	AppendMenuA, hPopMenu, MF_STRING, EXIT, offset szMenuExit
	mov		stSystray.st_cbsize, size NOTIFYICONDATA
	push	hDlg
	pop		stSystray.st_hWnd
	mov		stSystray.st_uID, SYSTRAY
	call	LoadIcon, hApp, ID_ICON
	push	hIcon
	pop 	stSystray.st_hIcon
	mov     stSystray.st_uFlags, NIF_ICON+NIF_MESSAGE+NIF_TIP
	mov     stSystray.st_uCallbackMessage, WM_SHELLNOTIFY
	call 	Shell_NotifyIcon, NIM_ADD, offset stSystray
	ret

SetSysTrayIcon	ENDP
	
End Start