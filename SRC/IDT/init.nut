/*+--------------------------------------------------------------------------------+
|                           PCapture Vscripts Library                              |
+----------------------------------------------------------------------------------+
| Author:                                                                          |
|     Data Structure Maestro - laVashik ^v^                                        |
+----------------------------------------------------------------------------------+
|   The Improved Data Types module: the pcapEntity wrapper and the entLib entity   |
|   factory, plus the ArrayEx, List and AVLTree containers.                        |
+----------------------------------------------------------------------------------+ */

IncludeScript("PCapture-LIB/SRC/IDT/entity")
IncludeScript("PCapture-LIB/SRC/IDT/entity_creator")

IncludeScript("PCapture-LIB/SRC/IDT/array")
IncludeScript("PCapture-LIB/SRC/IDT/list")
IncludeScript("PCapture-LIB/SRC/IDT/tree_sort")

// The env_entity_dissolver shared by pcapEntity.Dissolve.
if(("dissolver" in getroottable()) == false) {
    ::dissolver <- entLib.CreateByClassname("env_entity_dissolver", {targetname = "@dissolver"})
} 