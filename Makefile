fname := nimbang.nim

cat:
	cat Makefile

c:
	nim c ${fname}

rel:
	nim c -d:release ${fname}

small:
	nim c -d:release --opt:size --passL:-s ${fname}
