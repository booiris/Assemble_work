.386
.model flat, stdcall
option casemap :none

include windows.inc
include user32.inc
includelib user32.lib 
include kernel32.inc
includelib kernel32.lib 
include comdlg32.inc
includelib comdlg32.lib 

.data?
h_instance dword ?
h_main_window dword ?
h_window_edit1 dword ?
h_window_edit2 dword ?
h_old_window_edit1 dword ?
h_old_window_edit2 dword ?
h_file dword ?
str_file_name byte MAX_PATH dup(?)
str_buffer1 byte 10005 dup(?)
str_buffer2 byte 10005 dup(?)
st_cf CHARFORMAT2 {}
h_forward_edit dword ?
 
wrong_line dword 50000 dup (?)
wrong_line_cnt dword ?


.data

.const
str_class_name byte 'compare_window', 0
str_status_class_name byte 'msctls_statusbar32', 0
str_caption_main byte '文件比较', 0
str_caption_edit byte '比较完成', 0
str_same byte '文本相同', 0
str_edit_dll byte 'RichEd20.dll', 0
str_edit_class_name byte 'RichEdit20A', 0
str_filter byte 'Text Files(*.txt)',0,'*.txt',0
		byte	'All Files(*.*)',0,'*.*',0,0
str_font	db	'宋体',0
str_default_ext byte 'txt', 0
str_err_openfile byte '无法打开文件!', 0
str_load_file1 byte '打开文件1', 0
str_load_file2 byte '打开文件2', 0
szButton	byte	'button',0
szButtonText	byte	'开始比较',0
dwStatusWidth	dword	100,200,350,500,-1
str_chars_format	byte	'总长度:%d',0
str_sumline_format	byte	'总行数:%d',0
str_line_format	byte	'行:%d',0
str_col_format	byte	'列:%d',0

.code

_ProcStream	proc uses ebx edi esi _dwCookie,_lpBuffer,_dwBytes,_lpBytes

    .if	_dwCookie
        invoke	ReadFile,h_file,_lpBuffer,_dwBytes,_lpBytes,0
    .else
        invoke	WriteFile,h_file,_lpBuffer,_dwBytes,_lpBytes,0
    .endif
    xor	eax,eax
    ret

_ProcStream	endp

_load_file PROC uses esi edi 
    LOCAL st_of:OPENFILENAME
    LOCAL st_es:EDITSTREAM

    invoke	RtlZeroMemory,addr st_of,sizeof st_of
    mov	st_of.lStructSize,sizeof st_of
    push h_main_window
    pop	st_of.hwndOwner
    mov	st_of.lpstrFilter,offset str_filter
    mov	st_of.lpstrFile,offset str_file_name
    mov	st_of.nMaxFile,MAX_PATH
    mov	st_of.Flags,OFN_FILEMUSTEXIST or OFN_PATHMUSTEXIST
    mov	st_of.lpstrDefExt,offset str_default_ext
    invoke	GetOpenFileName,addr st_of
    .if	eax
        invoke	CreateFile,addr str_file_name,GENERIC_READ or GENERIC_WRITE,\
				FILE_SHARE_READ or FILE_SHARE_WRITE,0,OPEN_EXISTING,FILE_ATTRIBUTE_NORMAL,0
        push eax
        .if	h_file
            invoke CloseHandle,h_file
        .endif
        pop	eax
        mov	h_file,eax

        mov	st_es.dwCookie,TRUE
        mov	st_es.pfnCallback,offset _ProcStream
        invoke	SendMessage,h_forward_edit,EM_STREAMIN,SF_TEXT,addr st_es
        invoke	SendMessage,h_forward_edit,EM_SETMODIFY,FALSE,0
    .endif

    ret
_load_file ENDP

_text_compare PROC uses esi edi
    LOCAL line1_cnt:dword, char1_pos:dword, line2_cnt:dword, char2_pos:dword, flag:dword
    LOCAL all_flag:dword,father:dword

    mov all_flag, 1
    mov st_cf.dwMask, CFM_BACKCOLOR
    mov wrong_line_cnt, 0
    mov father, 0

    invoke SendMessage, h_window_edit1, EM_GETLINECOUNT, 0, 0
    mov line1_cnt,eax
    invoke SendMessage, h_window_edit2, EM_GETLINECOUNT, 0, 0
    mov line2_cnt,eax
    mov ebx, 0

    .while ebx != line1_cnt
        mov flag, 1

        invoke SendMessage, h_window_edit1, EM_LINEINDEX, ebx,0
        mov char1_pos, eax
        invoke SendMessage, h_window_edit1, EM_LINELENGTH, char1_pos, 0
        add eax, char1_pos
        invoke SendMessage, h_window_edit1, EM_SETSEL, char1_pos, eax
        invoke SendMessage, h_window_edit1, EM_GETSELTEXT,0, offset str_buffer1
        mov esi, offset str_buffer1
        mov byte ptr [esi+eax], 0

        invoke SendMessage, h_window_edit2, EM_LINEINDEX, ebx,0
        mov char2_pos, eax
        invoke SendMessage, h_window_edit2, EM_LINELENGTH, char2_pos, 0
        add eax, char2_pos
        invoke SendMessage, h_window_edit2, EM_SETSEL, char2_pos, eax
        invoke SendMessage, h_window_edit2, EM_GETSELTEXT,0, offset str_buffer2
        mov esi, offset str_buffer2
        mov byte ptr [esi+eax], 0

        mov esi, offset str_buffer1
        mov edi, offset str_buffer2

        .while flag == 1
            mov eax, [esi]
            .if al != [edi]
                mov flag, 0
            .endif
            inc esi
            inc edi 
            .break .if flag == 0 || byte ptr [esi] == 0 || byte ptr [edi] == 0
        .endw

        .if byte ptr [esi] !=0 || byte ptr [edi] !=0
            mov flag, 0
        .endif

        mov esi, offset wrong_line
        .if flag == 0
            mov all_flag, 0
            inc wrong_line_cnt
            mov eax, father
            mov [esi+4*eax], ebx
            mov father, ebx
            mov st_cf.crBackColor, 0000FF00h
            invoke SendMessage, h_window_edit1, EM_SETCHARFORMAT, SCF_SELECTION,addr st_cf

            mov st_cf.crBackColor, 000000FFh
            invoke SendMessage, h_window_edit2, EM_SETCHARFORMAT, SCF_SELECTION,addr st_cf
        .else
            mov st_cf.crBackColor, 00FFFFFFh
            invoke SendMessage, h_window_edit1, EM_SETCHARFORMAT, SCF_SELECTION ,addr st_cf
            invoke SendMessage, h_window_edit2, EM_SETCHARFORMAT, SCF_SELECTION ,addr st_cf
        .endif

        inc ebx
        .break .if ebx == line2_cnt
    .endw

    invoke SendMessage, h_window_edit1, EM_SETSEL, -1, -1
    invoke SendMessage, h_window_edit2, EM_SETSEL, -1, -1
    mov st_cf.crBackColor, 00FFFFFFh
    invoke SendMessage, h_window_edit1, EM_SETCHARFORMAT, SCF_SELECTION ,addr st_cf
    invoke SendMessage, h_window_edit2, EM_SETCHARFORMAT, SCF_SELECTION ,addr st_cf

    .if all_flag == 1
        invoke MessageBox, h_main_window, offset str_same, offset str_caption_edit, MB_OK
    .endif
    ret
_text_compare ENDP

_init PROC

    invoke	CreateWindowEx,NULL,\
				offset szButton,offset szButtonText,\
				WS_CHILD or WS_VISIBLE,\
				450,605,200,30,\
				h_main_window,5,h_instance,NULL

    invoke	CreateWindowEx,NULL,\
				offset szButton,offset str_load_file1,\
				WS_CHILD or WS_VISIBLE,\
				120,605,200,30,\
				h_main_window,3,h_instance,NULL

    invoke	CreateWindowEx,NULL,\
				offset szButton,offset str_load_file2,\
				WS_CHILD or WS_VISIBLE,\
				750,605,200,30,\
				h_main_window,4,h_instance,NULL

    invoke CreateWindowEx, WS_EX_CLIENTEDGE, \
    offset str_edit_class_name, NULL, \
    WS_CHILD or WS_VISIBLE or WS_VSCROLL or \
    WS_HSCROLL or ES_MULTILINE, \
    0, 0, 545, 600, h_main_window, 0, \
    h_instance, NULL
    mov h_window_edit1, eax

    invoke CreateWindowEx, WS_EX_CLIENTEDGE,\
    offset str_edit_class_name, NULL, \
    WS_CHILD or WS_VISIBLE or WS_VSCROLL or \
    WS_HSCROLL or ES_MULTILINE, \
    545, 0, 545, 600, h_main_window, 1, \
    h_instance, NULL
    mov h_window_edit2, eax

    ; invoke SetWindowLong, h_window_edit1, GWL_WNDPROC, addr _proc_edit1
    ; mov h_old_window_edit1, eax

    ; invoke SetWindowLong, h_window_edit2, GWL_WNDPROC, addr _proc_edit2
    ; mov h_old_window_edit2, eax


    invoke SendMessage, h_window_edit1, EM_SETCHARFORMAT, 0 ,addr st_cf
    invoke SendMessage, h_window_edit1, EM_SETLANGOPTIONS, 0, 0

    invoke SendMessage, h_window_edit2, EM_SETCHARFORMAT, 0 ,addr st_cf
    invoke SendMessage, h_window_edit2, EM_SETLANGOPTIONS, 0, 0


    ret
_init ENDP

_quit PROC
    invoke	DestroyWindow,h_main_window
	invoke	PostQuitMessage,NULL
    ret 
_quit ENDP

_proc_main_window PROC uses ebx edi esi h_window,u_msg,wParam,lParam
    
    mov	eax,u_msg
    .if eax ==  WM_CREATE
        push h_window
        pop h_main_window
        call _init
    .elseif eax == WM_COMMAND
        mov eax, wParam
        mov ecx, wParam
        shr eax, 16
        
        .if ax == BN_CLICKED
            .if cx == 5
                call _text_compare
            .elseif cx == 3
                mov eax, h_window_edit1 
                mov h_forward_edit,eax 
                call _load_file
            .elseif cx == 4
                mov eax, h_window_edit2
                mov h_forward_edit,eax
                call _load_file
            .endif
        .endif
    .elseif eax == WM_CLOSE
        call _quit
    .else
        invoke DefWindowProc, h_window, u_msg, wParam, lParam
        ret
    
    .endif

    xor eax, eax
    ret
_proc_main_window ENDP


_main_window PROC
    LOCAL st_window_class:WNDCLASSEX
    LOCAL st_msg:MSG
    LOCAL h_edit:dword

    mov st_cf.cbSize, sizeof st_cf
    mov st_cf.yHeight, 13 * 20
    mov st_cf.dwMask, CFM_FACE or CFM_SIZE or CFM_BOLD or CFM_COLOR
    invoke	lstrcpy,addr st_cf.szFaceName,addr str_font

    invoke LoadLibrary, offset str_edit_dll
    mov h_edit, eax
    invoke GetModuleHandle, NULL
    mov h_instance, eax

    invoke RtlZeroMemory, addr st_window_class, sizeof st_window_class
    invoke	LoadCursor,0,IDC_ARROW
    mov	st_window_class.hCursor,eax
    push h_instance
    pop	st_window_class.hInstance
    mov	st_window_class.cbSize,sizeof WNDCLASSEX
    mov	st_window_class.style,CS_HREDRAW or CS_VREDRAW
    mov	st_window_class.lpfnWndProc,offset _proc_main_window
    mov	st_window_class.hbrBackground,COLOR_BTNFACE+1
    mov	st_window_class.lpszClassName,offset str_class_name
    invoke RegisterClassEx, addr st_window_class

    invoke CreateWindowEx, WS_EX_OVERLAPPEDWINDOW, \
    offset str_class_name, \
    offset str_caption_main, \
    WS_OVERLAPPEDWINDOW xor WS_SIZEBOX, \
    100, 100, 1100, 700, NULL, NULL, h_instance, NULL
    mov h_main_window, eax
    invoke ShowWindow, h_main_window, SW_SHOWNORMAL
    invoke UpdateWindow, h_main_window

    .while TRUE
        invoke GetMessage, addr st_msg, NULL, 0 , 0
        .break .if eax == 0
        invoke	TranslateMessage,addr st_msg
		invoke	DispatchMessage,addr st_msg
    .endw
    invoke FreeLibrary, h_edit

    ret
_main_window ENDP

start:
    call _main_window
    invoke ExitProcess, NULL
    ret
end start