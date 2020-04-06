; SQUINT, Sparse Quad Union Indexed Nibble Trie 
; Copyright (c) 2020 Andrew Ferguson aka Idle
; Version 1.0.2 
; PB 5.71 x86 x64 Linux OSX Windows
; Thanks Wilbert for the high low insight to save a bit more memory
; Squint is the result of noting that you can reduce a trie from 256 nodes to 16 nodes
; at only the cost of 2 times the lookup and index by nibbles, then you realise you can
; use a quad to store the index to 16 offsets into a sparse array and also reduce the structure
; down to two control words per node. *vector,(squint.q | value.i): key->squint->*vector\e[offset] 
; resulting in a very compact trie with O(K*2) performance and a memory size 32 times smaller!
; four times smaller than a fixed 16 node trie and eight times smaller again than a 256 node trie.  
; Overhead on x64 reduces to ~8 bytes per byte of input with Unicode16 strings 
; Overhead on x86 reduces to ~6 bytes per byte of input with Unicode16 strings
; In pointer sizes thats ~1 word per word of input on x64 and ~1.5 words on x86
; which are similar to the overheads of a QP Trie thats a 1/3 smaller than a Critbit.
; In terms of speed it should be ~2 times that of a map lookup on average but that's OK as it is O(k*2)
; though if you're frequently looking up values that don't exist it will improve further as it will bail
; out earlier, plus as it's also very cache friendly it may come in closer to 1:1 on lookups. 
; Enumerations are of course magnitudes faster, which is why you'd be using a trie in the 1st place  

; see https://dotat.at/prog/qp/blog-2015-10-04.html
;     https://cr.yp.to/critbit.html 
;     https://en.wikipedia.org/wiki/Trie

; Keys can either be numeric integers, UTF8 or Unicode strings, default is Unicode for convienence
; and both can be used together though UTF8 is better for speed and size with strings. 
;
; Supports Set Get Enum Walk Delete and Prune with a flag in Delete
; 
; todo: add in a string buffer so value can be used for something else and still return the keys and value 

; License MIT
; Copyright (c) 2020 Andrew Ferguson 
; Permission is hereby granted, free of charge, to any person obtaining a copy
; of this software and associated documentation files (the "Software"), to deal
; in the Software without restriction, including without limitation the rights
; To use, copy, modify, merge, publish, distribute, sublicense, and/or sell
; copies of the Software, and to permit persons to whom the Software is
; furnished to do so, subject to the following conditions:
; 
; The above copyright notice and this permission notice shall be included in all
; copies or substantial portions of the Software.
; 
; THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS Or
; IMPLIED, INCLUDING BUT Not LIMITED To THE WARRANTIES OF MERCHANTABILITY,
; FITNESS For A PARTICULAR PURPOSE And NONINFRINGEMENT. IN NO EVENT SHALL THE
; AUTHORS Or COPYRIGHT HOLDERS BE LIABLE For ANY CLAIM, DAMAGES Or OTHER
; LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT Or OTHERWISE, ARISING FROM,
; OUT OF Or IN CONNECTION With THE SOFTWARE Or THE USE Or OTHER DEALINGS IN THE
; SOFTWARE. 

DeclareModule SQUINT 
  
  Structure squint_node 
    *vertex.edge       ;vector of child nodes max 16 
    StructureUnion
      squint.q         ;4 bit index of 16 child nodes
      value.i          ;value 
    EndStructureUnion 
  EndStructure   
  
  Structure edge 
    e.squint_node[0] 
  EndStructure 
  
  Structure squint 
    *vt
    size.l
    datasize.l
    count.l
    *root.squint_node 
  EndStructure
  
  CompilerIf #PB_Compiler_Processor = #PB_Processor_x86 
    #Squint_Pmask = $ffffffff
  CompilerElse 
    #Squint_Pmask = $ffffffffffff
  CompilerEndIf
  
  Prototype Squint_CB(*key,*userdata=0)
  
  Declare Squint_New() 
  Declare Squint_Free(*this.Squint) 
  Declare Squint_Delete(*this.squint,*key,len,prune=0,stringformat=#PB_Unicode)
  Declare Squint_Set(*this.squint,*key,len,value.i=0,stringformat=#PB_Unicode)
  Declare Squint_Get(*this.squint,*key,len,stringformat=#PB_Unicode)
  Declare Squint_Enum(*this.squint,*key,len,*pfn.squint_CB,*userdata=0,ReturnMatch=0,stringformat=#PB_Unicode)
  Declare Squint_Walk(*this.squint,*pfn.squint_CB,*userdata=0) 
  
  Interface iSquint
    Free()
    Delete(*key,len,prune=0,stringformat=#PB_Unicode)
    Set(*key,len,value.i=0,stringformat=#PB_Unicode)
    Get(*key,len,stringformat=#PB_Unicode)
    Enum(*key,len,*pfn.squint_CB,*userdata=0,ReturnMatch=0,stringformat=#PB_Unicode)
    Walk(*pfn.squint_CB,*userdata=0) 
  EndInterface  
  
  DataSection: vtSquint:
    Data.i @Squint_Free()
    Data.i @Squint_Delete() 
    Data.i @Squint_Set()
    Data.i @Squint_Get()
    Data.i @Squint_Enum()
    Data.i @Squint_Walk() 
  EndDataSection   
  
EndDeclareModule 

Module SQUINT 
  
  EnableExplicit 
  
  Macro SetIndex(in,index,number)
    in = in & ~(15 << (index << 2)) | (number << (index << 2))
  EndMacro
  
  Macro GetNodeCount() 
    CompilerIf #PB_Compiler_Processor = #PB_Processor_x86 
      nodecount = MemorySize(*node\vertex) / SizeOf(squint_node) 
    CompilerElse 
      nodecount = (*node\vertex >> 48)
    CompilerEndIf   
  EndMacro   
  
  Procedure Squint_New() 
    Protected *this.squint,a
    *this = AllocateMemory(SizeOf(squint)) 
    If *this 
      *this\vt = ?vtSquint 
      *this\root = AllocateMemory(SizeOf(squint_node)) 
      *this\root\vertex = AllocateMemory(SizeOf(squint_node)*16) 
      CompilerIf #PB_Compiler_Processor = #PB_Processor_x64 
        *this\root\vertex | (16 << 48)
      CompilerEndIf
      *this\size = 17 * SizeOf(squint_node)
      *this\count=1
      *this\root\squint=-1
      For a = 0 To 15 
        SetIndex(*this\root\squint,a,a)
      Next 
      ProcedureReturn *this
    EndIf 
  EndProcedure  
  
  Procedure Squint_Ifree(*this.squint,*node.squint_node=0) 
    Protected a,offset,nodecount 
    If Not *node 
      ProcedureReturn 0
    EndIf
    For a=0 To 15 
      offset = (*node\squint >> (a<<2)) & $f
      If *node\vertex 
        GetNodeCount()
        If (offset <> 15 Or nodecount = 16)
          Squint_IFree(*this,*node\Vertex\e[offset] & #Squint_Pmask)
        EndIf
      EndIf   
    Next
    If *node\vertex   
      GetNodeCount()
      *this\size - nodecount 
      *this\count - 1 
      FreeMemory(*node\Vertex & #Squint_Pmask) 
      *node\vertex=0
    EndIf
    ProcedureReturn *node
  EndProcedure   
  
  Procedure Squint_Free(*this.squint)
    Protected a,offset,*node.squint_node,nodecount 
    *node = *this\root 
    For a=0 To 15 
      offset = (*node\squint >> (a<<2)) & $f
      If *node\vertex 
        GetNodeCount()
        If (offset <> 15 Or nodecount = 16)
          Squint_IFree(*this,*node)
        EndIf
      EndIf   
    Next  
    FreeMemory(*this\root)
    nodecount = *this\count  
    FreeMemory(*this)
    ProcedureReturn nodecount 
  EndProcedure 
  
  Procedure Squint_Delete(*this.squint,*key,len,prune=0,stringformat=#PB_Unicode) 
    Protected *ikey,ilen,*node.squint_node,a,b,idx,*mem.Ascii,offset,nodecount
    If stringformat = #PB_Unicode 
      *ikey = UTF8(PeekS(*key,len))
      len = MemorySize(*ikey)-1 
    Else 
      *ikey = *key 
      len-1
    EndIf 
    ilen = (len*2)-1
    *node = *this\root   
    For a = 0 To ilen
      *mem = *ikey + (a>>1) 
      idx = (*mem\a >> (((a+1)&1) << 2)) & $f 
      offset = (*node\squint >> (idx<<2)) & $f  
      If *node\vertex 
        GetNodeCount()
        If (offset <> 15 Or nodecount = 16)  
          *node = *node\Vertex\e[offset] & #Squint_Pmask
        EndIf   
      Else 
        If stringformat = #PB_Unicode 
          FreeMemory(*ikey)
        EndIf   
        ProcedureReturn 
      EndIf
    Next 
    If prune 
      Squint_Ifree(*this,*node)
      If (*node\vertex & #Squint_Pmask) = 0 
        *node\squint = 0  
      EndIf 
    Else 
      ilen+2
      For b = a To ilen
        *mem = *ikey + (b>>1)
        idx = (*mem\a >> (((b+1)&1) << 2)) & $f  
        offset = (*node\squint >> (idx<<2)) & $f 
        If *node\vertex 
          GetNodeCount()
          If (offset <> 15 Or nodecount = 16)  
            *node = *node\Vertex\e[offset] & #Squint_Pmask
          EndIf   
          If (*node\vertex & #Squint_Pmask) = 0 
            *node\squint = 0 
          EndIf
        EndIf
      Next  
    EndIf
    If stringformat = #PB_Unicode 
      FreeMemory(*ikey)
    EndIf 
    
  EndProcedure   
  
  Procedure Squint_Set(*this.squint,*key,len,value.i=0,stringformat=#PB_Unicode)
    Protected *node.squint_node,*ikey,ilen,a,idx,*mem.Ascii,offset,nodecount
    *node = *this\root & #Squint_Pmask
    *this\datasize + len 
    If stringformat = #PB_Unicode 
      *ikey = UTF8(PeekS(*key,len))
      len = MemorySize(*ikey)
    Else 
      *ikey = *key
    EndIf 
    ilen = (len*2)-1
    For a = 0 To ilen
      *Mem = *ikey + (a>>1)  
      idx = (*mem\a >> (((a+1)&1) << 2)) & $f  ;look up nibble high low order 
      offset = (*node\squint >> (idx<<2)) & $f ;look up offset in vertext vector  
      If *node\vertex                          ;check it's allocated  
        GetNodeCount()                         ;get node count required for check  
        If offset <= nodecount                 ;if the node is set proceed to next node  
          *node = *node\Vertex\e[offset] & #Squint_Pmask
        Else                                   ;append child node  
          *this\size + SizeOf(squint_node)
          offset = nodecount 
          nodecount+1
          *node\vertex = ReAllocateMemory(*node\vertex & #Squint_Pmask,(nodecount)*SizeOf(squint_node))
          CompilerIf #PB_Compiler_Processor = #PB_Processor_x64 
            *node\vertex | ((nodecount) << 48) 
          CompilerEndIf  
          SetIndex(*node\squint,idx,offset)      ;poke the offset to the squint index 
          *node = *node\Vertex\e[offset] & #Squint_Pmask
        EndIf   
      Else                                     ;allocate a new node 
        *this\size + SizeOf(squint_node)
        *node\vertex = AllocateMemory(SizeOf(squint_Node))
        CompilerIf #PB_Compiler_Processor = #PB_Processor_x64 
          *node\vertex | (1 << 48) 
        CompilerEndIf
        *node\squint = -1 
        SetIndex(*node\squint,idx,0) 
        *node = *node\Vertex\e[0] & #Squint_Pmask
        *this\count+1
      EndIf 
    Next 
         
    If stringformat = #PB_Unicode 
      FreeMemory(*ikey)
    EndIf
    
    If value 
      *node\value = value
    EndIf   
    
    ProcedureReturn *node 
    
  EndProcedure 
  
  Procedure Squint_Get(*this.squint,*key,len,stringformat=#PB_Unicode)
    Protected *ikey,ilen,*node.squint_Node,a,idx,*mem.Ascii,offset,result,nodecount
    If stringformat = #PB_Unicode 
      *ikey = UTF8(PeekS(*key,len))
      len = MemorySize(*ikey) 
    Else 
      *ikey = *key 
    EndIf 
    *node = *this\root & #Squint_Pmask
    ilen = (len*2)-1
    For a = 0 To ilen
      *Mem = *ikey + (a>>1) 
      idx = (*mem\a >> (((a+1)&1) << 2)) & $f  ;look up nibble high low order
      offset = (*node\squint >> (idx<<2)) & $f ;look up offset in vertext vector 
      If *node\vertex   
        GetNodeCount()                         ;get node count 
        If offset <= nodecount                 ;check it's a valid child 
          *node = (*node\Vertex\e[offset] & #Squint_Pmask) 
          result = *node\value
        Else   
          result=0
          Break 
        EndIf
      Else 
        result=0
        Break 
      EndIf
    Next
    If stringformat = #PB_Unicode 
      FreeMemory(*ikey)
    EndIf
    ProcedureReturn result
  EndProcedure 
  
  Procedure Squint_IEnum(*this.squint,*node.squint_Node,depth,*pfn.squint_CB,*userdata=0)
    Protected a.i,offset,nodecount 
    If Not *node 
      ProcedureReturn 0
    EndIf
    For a=0 To 15 
      offset = (*node\squint >> (a<<2)) & $f   ;need to loop 0 to 15 to maintain order
      If (*node\vertex And *node\squint)
        GetNodeCount()                         ;get node count 
        If (offset <> 15 Or nodecount = 16)    ;check it's valid 
          Squint_IEnum(*this,*node\Vertex\e[offset] & #Squint_Pmask,depth+1,*pfn,*userdata)
        EndIf
      EndIf 
    Next
    If (*node\vertex=0 And *node\squint)
      If *pfn
        *pfn(*node\value,*userdata)
      EndIf
    EndIf   
    ProcedureReturn *node
  EndProcedure
  
  Procedure Squint_Enum(*this.squint,*key,len,*pfn.squint_CB,*userdata=0,ReturnMatch=0,stringformat=#PB_Unicode)
    Protected *node.squint_Node,idx,ilen,*mem.Ascii,a,*ikey,lkey,offset,nodecount
    If stringformat = #PB_Unicode    
      *ikey = UTF8(PeekS(*key,len))
      len = MemorySize(*ikey) 
      ilen =((len-1)*2)-1 
    Else 
      *ikey = *key
      ilen =(len*2)-1 
    EndIf 
    If ReturnMatch
      If squint_Get(*this,*ikey,len,stringformat)
        If *pfn
          *pfn(*ikey,*userdata)
        EndIf
        ProcedureReturn
      EndIf
    EndIf   
    *node = *this\root
    For a = 0 To ilen
      *Mem = *ikey + (a>>1) 
      idx = (*mem\a >> (((a+1)&1) << 2)) & $f  ;look up nibble high low order
      offset = (*node\squint >> (idx<<2)) & $f ;look up offset in vertext vector
      If (*node\vertex And *node\squint)       ;check node has children   
        GetNodeCount()                         ;get node count 
        If (offset <> 15 Or nodecount = 16)    ;check it's valid 
          *node = *node\Vertex\e[offset] & #Squint_Pmask
        EndIf
      EndIf
      If Not *node Or *node\vertex = 0
        If stringformat = #PB_Unicode 
          FreeMemory(*ikey)
        EndIf   
        ProcedureReturn 0
      EndIf
    Next   
    Squint_IEnum(*this,*node,a,*pfn,*userdata)
    If stringformat = #PB_Unicode 
      FreeMemory(*ikey)
    EndIf 
  EndProcedure
  
  Procedure Squint_Walk(*this.squint,*pfn.squint_CB,*userdata=0) 
    Squint_IEnum(*this,*this\root,0,*pfn,*userdata)
  EndProcedure  
    
  DisableExplicit
  
EndModule 
