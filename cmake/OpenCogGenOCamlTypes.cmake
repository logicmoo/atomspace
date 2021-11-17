#
# OpenCogGenOCamlTypes.cmake
#
# Definitions for automatically building the OCaml `atom_types.ml`
# file, given a master file `atom_types.script`.
#
# Example usage:
# OPENCOG_OCAML_ATOMTYPES(atom_types.script core_types.ml)
#
# ===================================================================

MACRO(OPENCOG_OCAML_SETUP OCAML_FILE WRAPPER_FILE HEADER_FILE)
	IF (NOT OCAML_FILE)
		MESSAGE(FATAL_ERROR "OPENCOG_OCAML_ATOMTYPES missing OCAML_FILE")
	ENDIF (NOT OCAML_FILE)

	MESSAGE(DEBUG "Generating OCaml Atom Type definitions from ${SCRIPT_FILE}.")

	FILE(WRITE "${OCAML_FILE}"
		"\n"
		"(* DO NOT EDIT THIS FILE! This file was automatically *)\n"
		"(* generated from atom definitions in *)\n"
		"(* ${SCRIPT_FILE} *)\n"
		"(* by the macro OPENCOG_OCAML_ATOMTYPES *)\n"
		"\n"
		"(* This file contains basic OCaml wrappers for atom creation. *)\n"
		"\n"
		"type atom = Atom ;; (* | Node of string | Link of atom list;; *)\n"
		"\n"
		"external atom_printer : atom -> string = \"atom_string_printer\" ;;\n"
		"\n"
		"(* We need a pretty-printer for each set of atom types *)\n"
		"(* #install_printer atom_prettyprt ;; *)\n"
		"let atom_prettyprt : Format.formatter -> atom -> unit =\n"
		"	function oport ->\n"
		"		fun atm -> Format.fprintf oport \"%s\" (atom_printer atm) ;;\n"
		"\n"
	)

	FILE(WRITE "${WRAPPER_FILE}"
		"//\n"
		"// DO NOT EDIT THIS FILE! This file was automatically\n"
		"// generated from atom definitions in\n"
		"// ${SCRIPT_FILE}\n"
		"// by the macro OPENCOG_OCAML_ATOMTYPES\n"
		"//\n"
		"// This file contains basic OCaml wrappers for atom creation.\n"
		"//\n"
		"#define CAML_NAME_SPACE\n"
		"#include <caml/memory.h>\n"
		"#include <caml/mlvalues.h>\n"
		"#include <opencog/ocaml/CamlWrap.h>\n"
		"\n"
		"#include <${HEADER_FILE}>\n"
		"#include <opencog/atoms/base/Atom.h>\n"
		"#include <opencog/atoms/base/Handle.h>\n"
		"\n"
		"using namespace opencog;\n"
		"\n"
		"extern \"C\" {\n"
		"\n"
	)
ENDMACRO()

MACRO(OPENCOG_OCAML_TEARDOWN OCAML_FILE)
	FILE(APPEND "${WRAPPER_FILE}"
		"} // extern \"C\"\n"
	)
ENDMACRO()

# Print out the scheme definitions
MACRO(OPENCOG_OCAML_WRITE_DEFS OCAML_FILE WRAPPER_FILE)

	# The function that returns the integer type of the type.
	# Not needed right now, comment out.
	# FILE(APPEND "${OCAML_FILE}"
	#	"external ${LC_SNAKE_TYPE}_atomtype : unit -> int = \"${TYPE_NAME}Type\" ;;\n"
	# )
	#
	# FILE(APPEND "${WRAPPER_FILE}"
	#	"CAMLprim value  ${TYPE_NAME}Type(void) {\n"
	#	"    CAMLparam0();\n"
	#	"    CAMLreturn(Val_long(${TYPE})); } \n"
	# )

	# Use short names, whenever possible. There are no backwards-compat
	# issues here with the long names.
	SET(ML_NAME ${LC_SNAKE_TYPE})
	IF (NOT LC_SNAKE_SHORT STREQUAL "")
		SET(ML_NAME ${LC_SNAKE_SHORT})
	ENDIF ()

	# Avoid reserved keywords
	IF (ML_NAME STREQUAL "list" OR
	    ML_NAME STREQUAL "true" OR
	    ML_NAME STREQUAL "false" OR
	    ML_NAME STREQUAL "and" OR
	    ML_NAME STREQUAL "or" OR
	    ML_NAME STREQUAL "type" OR
	    ML_NAME STREQUAL "virtual" OR
	    ML_NAME STREQUAL "function"
	   )
		SET(ML_NAME ${LC_SNAKE_TYPE})
	ENDIF ()

	IF (TYPE STREQUAL "NOTYPE" OR
	    TYPE STREQUAL "VALUATION" OR
	    TYPE STREQUAL "ATOM"
	   )
		# no-op; skip

	ELSEIF (ISVALUE STREQUAL "VALUE" OR ISSTREAM STREQUAL "STREAM")
		FILE(APPEND "${OCAML_FILE}"
			"external ${ML_NAME} : unit -> atom = \"new_${TYPE_NAME}\" ;;\n"
		)

	ELSEIF (ISNODE STREQUAL "NODE")
		FILE(APPEND "${OCAML_FILE}"
			"external ${ML_NAME} : string -> atom = \"new_${TYPE_NAME}\" ;;\n"
		)
		FILE(APPEND "${WRAPPER_FILE}"
			"CAMLprim value new_${TYPE_NAME}(value vname) {\n"
			"    CAMLparam1(vname);\n"
			"    CAMLreturn(NewNode(vname, ${TYPE}));\n"
			"}\n\n"
		)

	ELSEIF (ISLINK STREQUAL "LINK")
		FILE(APPEND "${OCAML_FILE}"
			"external ${ML_NAME} : atom list -> atom = \"new_${TYPE_NAME}\" ;;\n"
		)
		FILE(APPEND "${WRAPPER_FILE}"
			"CAMLprim value new_${TYPE_NAME}(value vatomlist) {\n"
			"    CAMLparam1(vatomlist);\n"
			"    CAMLreturn(NewLink(vatomlist, ${TYPE}));\n"
			"}\n\n"
		)

	ELSEIF (ISATOMSPACE STREQUAL "ATOMSPACE")
		# XXX FIXME LATER
		#FILE(APPEND "${OCAML_FILE}"
		#	"(define-public AtomSpace cog-new-atomspace)\n"
		#)

	ELSEIF (ISAST STREQUAL "AST")
		# XXX FIXME LATER
		#FILE(APPEND "${OCAML_FILE}"
		#	"(define-public (${TYPE_NAME} . x)\n"
		#	"\t(apply cog-new-ast (cons ${TYPE_NAME}Type x)))\n"
		#)
	ELSE ()
		MESSAGE(FATAL_ERROR "Unknown type ${TYPE}")
	ENDIF ()
ENDMACRO()

# ------------
# Main entry point.
MACRO(OPENCOG_OCAML_ATOMTYPES
	SCRIPT_FILE OCAML_FILE WRAPPER_FILE HEADER_FILE)

	OPENCOG_OCAML_SETUP(${OCAML_FILE} ${WRAPPER_FILE} ${HEADER_FILE})
	FILE(STRINGS "${SCRIPT_FILE}" TYPE_SCRIPT_CONTENTS)
	FOREACH (LINE ${TYPE_SCRIPT_CONTENTS})
		OPENCOG_TYPEINFO_REGEX()
		IF (MATCHED AND CMAKE_MATCH_1)

			OPENCOG_TYPEINFO_SETUP()
			OPENCOG_OCAML_WRITE_DEFS(${OCAML_FILE} ${WRAPPER_FILE})
		ELSEIF (NOT MATCHED)
			MESSAGE(FATAL_ERROR "Invalid line in ${SCRIPT_FILE} file: [${LINE}]")
		ENDIF ()
	ENDFOREACH (LINE)
	OPENCOG_OCAML_TEARDOWN(${OCAML_FILE})

ENDMACRO()

#####################################################################
