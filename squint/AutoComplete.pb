;AutoComplete example 

IncludeFile "Squint.pbi"

UseModule Squint 
EnableExplicit 
#Auto_Start =0 
#Auto_Get =1
#Auto_Enum =2 

Global *squint.iSquint = Squint_New()   
Global index,result
Global *buf = AllocateMemory(1024) 
Global itemsize=1024*1024
Global itempos 
Global *items = AllocateMemory(itemsize) 
Global *text
Global wordcount 
Global Dim inp.i(90000) 

Procedure ClearItems() 
  FillMemory(*items,itemsize,0) 
EndProcedure  

Procedure CBSquint(*key)
  Protected out.s,len 
  len = MemorySize(*key)-1
  If (itempos + len + 1) < MemorySize(*items) 
    CopyMemory(*key,*items+itempos,len)
    out = PeekS(*items+itempos,len,#PB_UTF8) 
    itempos + len 
    PokeA(*items+itempos,32)
    itempos + 1 
  Else 
    itemsize + len + 1 
    *items = ReAllocateMemory(*items,itemsize)
    CopyMemory(*key,*items+itempos,len)
    itempos + len 
    PokeA(*items+itempos,32)
    itempos + 1 
  EndIf   
EndProcedure   

Procedure LoadDicFile(Dicfile.s,*squint.ISquint)
  Protected fn,fm,pos,word.s,count 
  fn = ReadFile(#PB_Any,Dicfile)
  If fn
    fm = ReadStringFormat(fn)
    While Not Eof(fn)
      word = ReadString(fn,fm,-1)
      inp(count) = UTF8(word) 
      word = LCase(word)
      *squint\Set(@word,StringByteLength(word),inp(count),#PB_Unicode)
      count+1
    Wend
    CloseFile(fn)
  EndIf
  ProcedureReturn count
EndProcedure

Procedure ScintillaCallBack(Gadget, *scinotify.SCNotification)
  Static Auto_state.i     
  Static pos.i,space.i
  
  Protected mods = (#SC_MOD_DELETETEXT | #SC_PERFORMED_USER)
  Select *scinotify\nmhdr\code  
      
    Case #SCN_AUTOCSELECTION
      Auto_state = #Auto_Start 
      pos = 0 
    Case #SCN_MODIFIED
      If *scinotify\modificationType = mods Or *scinotify\modificationType =  (mods | #SC_STARTACTION)
        pos - *scinotify\length  
        If pos < 1 
          Auto_state = #Auto_Start 
          ScintillaSendMessage(0,#SCI_AUTOCCANCEL) 
          pos = 0 
        EndIf 
      EndIf   
    Case #SCN_CHARADDED   
      Select *scinotify\ch
        Case $A,$20  
          If Auto_state < #Auto_Enum  
            
            If *squint\Get(*buf,pos+1,#PB_UTF8) = 0 
              If wordcount < 90000 
                Inp(wordcount) = UTF8(PeekS(*buf,pos+1,#PB_UTF8)) 
                *squint\Set(inp(wordcount),MemorySize(inp(wordcount)),inp(wordcount),#PB_UTF8) 
                wordcount+1 
              EndIf   
            EndIf 
            Auto_state = #Auto_Start 
            pos=0 
          EndIf   
          
        Default
          PokeA(*buf+pos,*scinotify\ch)
          If pos > 1 
            Auto_state = #Auto_Get 
            ClearItems()
            *squint\Enum(*buf,pos+1,@CBSquint(),0,0,#PB_UTF8)
            itempos=0
            If ScintillaSendMessage(0,#SCI_AUTOCACTIVE) = 0
              ScintillaSendMessage(0,#SCI_AUTOCSHOW,pos+1,*items)   
            Else 
              ScintillaSendMessage(0,#SCI_AUTOCCANCEL) 
              ScintillaSendMessage(0,#SCI_AUTOCSHOW,pos+1,*items)  
            EndIf 
          EndIf
          pos+1
      EndSelect        
    Default 
      
  EndSelect       
  
EndProcedure

wordcount = loadDicfile("./words.txt",*squint)

If OpenWindow(0, 0, 0, 800, 600, "ScintillaGadget", #PB_Window_SystemMenu | #PB_Window_ScreenCentered)
  
  If InitScintilla()
    ScintillaGadget(0,0,0,800, 600,@ScintillaCallBack())
    ScintillaSendMessage(0,#SCI_AUTOCSETIGNORECASE,#True)
    ScintillaSendMessage(0,#SCI_AUTOCSETAUTOHIDE,0)
    ScintillaSendMessage(0,#SCI_AUTOCSETMAXHEIGHT,10)
    ScintillaSendMessage(0,#SCI_AUTOCSETORDER,#SC_ORDER_PRESORTED)
    ScintillaSendMessage(0, #SCI_STYLESETFORE, 0, RGB(0, 0, 0))
    *Text=UTF8(" ")
    ScintillaSendMessage(0, #SCI_AUTOCSTOPS,0,*text)
    FreeMemory(*Text) 
    *Text=UTF8("Autocomplete test in ScintillaGadget...")
    ScintillaSendMessage(0, #SCI_SETTEXT, 0,*Text)
    FreeMemory(*Text) 
  EndIf
  
  Repeat : Until WaitWindowEvent() = #PB_Event_CloseWindow
EndIf
CloseWindow(0) 

*squint\free()

