; extends
; Highlight import/export statements in MDX files with TSX syntax
((inline) @_inline (#match? @_inline "^(import|export)")) @tsx
