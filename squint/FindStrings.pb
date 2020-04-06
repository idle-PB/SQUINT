;Example of a FindStrings to find multiple occurances of tokens and return their positions

IncludeFile "Squint.pbi"

UseModule SQUINT 
EnableExplicit 

Structure Item 
  key.s 
  count.l
  len.l
  List positions.i()
EndStructure 

Structure FindStrings 
  List *item.item() 
EndStructure

Global FindStringsItems.FindStrings 
  
Procedure FindStrings(*squint.squint,*source,*keys,*items.FindStrings=0) 
  Protected *inp.Character,*node.squint_node,*sp    
  Protected count,key.s,*item.item    
  
  If *source 
    *inp = *source 
    *sp = *source 
    While *inp\c <> 0
      While *inp\c > 32 
        *inp+2 
      Wend 
      key = PeekS(*source,(*inp-*source)>>1)
      *node = Squint_set(*squint,@key,StringByteLength(key)) 
      If Not *node\value 
        *item =  AllocateStructure(item)
        AddElement(*item\positions()) 
        *item\positions() = *source - *sp
        *item\count = 1 
        *item\key = key 
        *item\len = (*inp-*source)>>1
        *node\value = *item
      Else   
        *item = *node\value 
        AddElement(*item\positions())
        *item\positions() = *source - *sp
        *item\len = (*inp-*source)>>1
        *item\count + 1 
      EndIf   
      If *inp\c <> 0
        *inp+2
        *source = *inp 
      Else 
        Break 
      EndIf   
    Wend 
  EndIf 
  
  *inp = *keys 
  While *inp\c <> 0
    While *inp\c > 32 
      *inp+2 
    Wend 
    key = PeekS(*keys,(*inp-*keys)>>1)
    *item = Squint_get(*squint,@key,StringByteLength(key)) 
    If *item
      count + *item\count  
      If *items
        If *item\count >= 1 
          AddElement(*items\item()) 
          *items\item() = *item 
        EndIf
      EndIf   
    EndIf   
    If *inp\c <> 0
      *inp+2
      *keys = *inp 
    Else 
      Break 
    EndIf   
  Wend 
  
  ProcedureReturn count 
  
EndProcedure 

Procedure cbFindStringsFree(*key,*data) 
  FreeStructure(*key) 
EndProcedure   

Procedure cbFindStringsEnum(*key,*items.FindStrings) 
  AddElement(*items\item()) 
  *items\item() = *key 
EndProcedure   

Procedure FindStringsFree(*squint.squint) 
  Squint_Walk(*squint,@cbFindStringsFree()) 
  Squint_Free(*squint) 
EndProcedure   

Procedure FindStringsEnum(*mt.squint,key.s,*items.FindStrings) 
  ClearList(*items\item())
  Squint_Enum(*mt,@key,StringByteLength(key),@cbFindStringsEnum(),*items) 
EndProcedure   

Global String1.s = "373 ac3 b9d45 b iPdC ks23 al97 373 ac5 al99 346 vs42159ssbpx roro ask ePOC foo bar xyz 12dk tifer erer e"
Global String2.s = "346 373 iPdC roro ePOC ac3"
Global String3.s = "b xyz erer" 
Global out.s
Global FindStringsItems.FindStrings 
Global *squint.squint = Squint_New() 

Debug FindStrings(*squint,@String1,@String2,@FindStringsItems)


ForEach FindStringsItems\item() 
  out=""
  Debug FindStringsItems\item()\key + " " + Str(FindStringsItems\item()\count)
  ForEach FindStringsItems\item()\positions() 
    out + Str(FindStringsItems\item()\positions()) + ": " + PeekS(@string1 + FindStringsItems\item()\positions(),FindStringsItems\item()\len) + " " 
  Next 
  Debug out 
Next

Debug "Enum from a" 

FindStringsEnum(*squint,"a",@FindStringsItems) 

ForEach FindStringsItems\item() 
  out=""
  Debug FindStringsItems\item()\key 
Next

FindStringsFree(*squint) 