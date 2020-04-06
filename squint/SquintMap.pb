;example benchmarking against a map. 
;compile as console and turn debugger off 

IncludeFile "Squint.pbi"

UseModule SQUINT 

Global mode = #PB_UTF8 

Procedure CBSquint(*key)
  PrintN(PeekS(*key,-1,mode))
EndProcedure  

Procedure EnumMap(Map mp(),key.s,len,mode) 
  Protected NewList items.s() 
  Protected word.s
  ForEach mp() 
    word = PeekS(mp(),-1,mode)
    If Left(word,len) = key 
      AddElement(items()) 
      items() = word 
    EndIf 
  Next   
  SortList(items(),#PB_Sort_Ascending) 
  ForEach items() 
    x.s = items() 
  Next 
EndProcedure   

Global *mt.squint = Squint_New() 
Global TmpPath.s = GetTemporaryDirectory() +"en-GB.dic"
Global Dim inp.i(90000)  
Global NewMap mp.i(90000)
Global AddTimeSquint.l, AddTimeMap.l,GetTimeSquint.l,GetTimeMap.l  
Global len,st,et,b 

OpenConsole() 

Procedure LoadDicFile(Dicfile.s)
  Protected fn,fm,pos,word.s,count,*mem  
  fn = ReadFile(#PB_Any,Dicfile)
  If fn
    fm = ReadStringFormat(fn)
    While Not Eof(fn)
      word = ReadString(fn,fm,-1)
      pos = FindString(word,"/")
      If pos > 0
        word = Left(word,pos-1)
      EndIf
      word = LCase(word)
      If mode = #PB_Unicode
        *mem = AllocateMemory(StringByteLength(word)+1)
        PokeS(*mem,word,StringByteLength(word),#PB_Unicode) 
        inp(count) = *mem
      Else   
        inp(count) = UTF8(word)
      EndIf   
      count+1
    Wend
    CloseFile(fn)
  EndIf
  ProcedureReturn count
EndProcedure

InitNetwork()
If FileSize(TmpPath) > 0 
  ct = loadDicfile(TmpPath)
ElseIf ReceiveHTTPFile("https://raw.githubusercontent.com/marcoagpinto/aoo-mozilla-en-dict/master/en_GB%20(Marco%20Pinto)/en-GB.dic",TmpPath)
  ct = loadDicfile(TmpPath)
Else
  MessageRequester("OOPS","failed to download")
  End
EndIf    

For b = 0 To 15 
  
  Squint_Free(*mt) 
  *mt.squint = Squint_New() 
  st = ElapsedMilliseconds() 
  For  a = 0 To ct-1  
    Squint_Set(*mt,inp(a),MemorySize(inp(a)),inp(a),mode)
  Next 
  et = ElapsedMilliseconds() 
  AddTimeSquint = (et-st) 
  
  FreeMap(Mp())
  NewMap mp.i(ct)
  st = ElapsedMilliseconds() 
  For  a = 0 To ct-1 
    mp(PeekS(inp(a),-1,mode)) = inp(a)
  Next 
  et = ElapsedMilliseconds() 
  AddTimeMap = (et-st)      
  
  st = ElapsedMilliseconds()  
  For a = 0 To ct-1
    out = Squint_Get(*mt,inp(a),MemorySize(inp(a)),mode)
  Next  
  et = ElapsedMilliseconds() 
  GetTimeSquint = et-st
  
  st = ElapsedMilliseconds()
  For a = 0 To ct-1
    out = mp(PeekS(inp(a),-1,mode))
  Next
  et = ElapsedMilliseconds() 
  GetTimeMap = et-st
  
  in.s = "cat"
  st = ElapsedMilliseconds() 
  For a = 0 To 15 
    Squint_Enum(*mt,@in,StringByteLength(in),0,0,0,#PB_Unicode) 
  Next 
  et= ElapsedMilliseconds()
  SquintEnum = et -st 
  
  st= ElapsedMilliseconds()
  For a = 0 To 15 
    EnumMap(mp(),in,Len(in),mode) 
  Next   
  et=ElapsedMilliseconds()
  MapEnum = et-st 
  
  TSquintAdd + AddTimeSquint 
  TmapAdd + AddtimeMap 
  TSquintGet + GetTimeSquint 
  TmapGet + GetTimeMap
  TSquintEnum + SquintEnum 
  TMapEnum + MapEnum
  
  PrintN("Squint add time = " + Str((AddTimeSquint))) 
  PrintN("Map add time = " + Str((AddTimeMap))) 
  PrintN("Squint lookup = " + Str((GetTimeSquint))) 
  PrintN("Map lookup = " + Str((GetTimeMap))) 
  PrintN("Squint enum time = " + Str((SquintEnum))) 
  PrintN("Map enum time = " + Str((MapEnum))) 
  PrintN("-----------------------------------------------")
  
Next 

Global strGarbage.s ="ZZPluralAlpha"
PrintN("testing garbage word " + Str(squint_get(*mt,@StrGarbage,StringByteLength(StrGarbage),#PB_Unicode)))
PrintN("-----------------------------------------------")
PrintN("Enum from cat") 
in.s = "cat"
Squint_Enum(*mt,@in,StringByteLength(in),@cbsquint(),0,0,#PB_Unicode) 
in.s = "catch"
Squint_Delete(*mt,@in,StringByteLength(in),0,#PB_Unicode) 
PrintN("-----------------------------------------------")
PrintN("Test Delete " + Str(squint_get(*mt,@in,StringByteLength(in),#PB_Unicode)))
PrintN("-----------------------------------------------")
in.s = "cat"
PrintN("Before Prune of cat " + Str(*mt\count) + " nodes")
Squint_Delete(*mt,@in,StringByteLength(in),1,#PB_Unicode)
PrintN("After Prune of cat " + Str(*mt\count) + " nodes") 
PrintN("Test Enum from cat") 
in.s = "cat"
Squint_Enum(*mt,@in,StringByteLength(in),@cbsquint(),0,0,#PB_Unicode) 
PrintN("-----------------------------------------------")

PrintN("Squint overhead " + StrF((*mt\size / *mt\datasize) / SizeOf(Integer)) + " Integers per Integer of Data overhead") 
PrintN("Squint overhaed " + StrF((*mt\size / *mt\datasize)) + " Bytes per Byte of Data overhead") 
PrintN("Squint Memory Size " + Str(*mt\size))  
PrintN("-----------------------------------------------")

PrintN("Squint add ratio = " + StrF((TSquintAdd / TmapAdd))) 
PrintN("Squint lookup ratio = " + StrF((TSquintGet / Tmapget))) 
PrintN("Squint enum ratio = " + StrF((tSquintEnum / tmapEnum))) 
PrintN("Map add ratio = " + StrF((TmapAdd / TSquintAdd))) 
PrintN("Map lookup ratio = " + StrF((TmapGet / TSquintGet))) 
PrintN("Map enum ratio  = " + StrF((tmapEnum / tSquintEnum))) 

PrintN("Free " + Str(Squint_Free(*mt))) 

Input() 