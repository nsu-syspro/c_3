
EXE_gcc = main_gcc
EXE_clang_asan = main_clang_asan
EXE_clang_msan = main_clang_msan
EXE_clang_stack = main_clang_stack

GCC = gcc
CLANG = clang
COMMON_CFLAGS = -std=c99 -Wall -Wextra -g -O0
ADVANCED_WARNINGS = -Weverything -Wno-unsafe-buffer-usage -Wno-declaration-after-statement -Wno-missing-prototypes
COMMON_ASAN = -fsanitize=address -fsanitize=pointer-compare -fsanitize=pointer-subtract -fsanitize=leak -fsanitize=undefined
COMMON_MSAN = -fsanitize=memory
COMMON_STACK = -fsanitize=safe-stack
IN = $(wildcard tests/*-input.txt)
ACT = $(IN:-input.txt=-actual-gcc.txt) $(IN:-input.txt=-actual-clang-asan.txt) $(IN:-input.txt=-actual-clang-msan.txt) $(IN:-input.txt=-actual-clang-stack.txt)
PASS = $(IN:-input.txt=.passed)


.PHONY: all clean test

all: test

clean:
	@rm -f $(PASS)
	rm -f $(ACT) $(EXE_gcc) $(EXE_clang_asan) $(EXE_clang_msan) $(EXE_clang_stack)


HEADERS = $(wildcard ./*.h)

$(EXE_gcc): *.c $(HEADERS)
	@clang-format --style=file main.c > main-formatted.c
	-diff main.c main-formatted.c
	@rm -f main-formatted.c
	$(GCC) $(COMMON_CFLAGS) $(COMMON_ASAN) *.c -o $@

$(EXE_clang_asan): *.c $(HEADERS)
	$(CLANG) $(COMMON_CFLAGS) $(ADVANCED_WARNINGS) $(COMMON_ASAN) *.c -o $@

$(EXE_clang_msan): *.c $(HEADERS)
	$(CLANG) $(COMMON_CFLAGS) $(COMMON_MSAN) *.c -o $@

$(EXE_clang_stack): *.c $(HEADERS)
	$(CLANG) $(COMMON_CFLAGS) $(COMMON_STACK) *.c -o $@

test: $(PASS)
	@echo "All tests passed"

$(PASS): %.passed: %-input.txt %-expected.txt $(EXE_gcc) $(EXE_clang_asan) $(EXE_clang_msan) $(EXE_clang_stack)
	@export ASAN_OPTIONS="detect_invalid_pointer_pairs=2:check_initialization_order=true:detect_stack_use_after_return=true:strict_string_checks=true"
	@echo "Running test $*..."
	@rm -f $@
	./$(EXE_gcc) $*-input.txt $*-actual-gcc.txt
	diff $*-expected.txt $*-actual-gcc.txt
	./$(EXE_clang_asan) $*-input.txt $*-actual-clang-asan.txt
	diff $*-expected.txt $*-actual-clang-asan.txt
	./$(EXE_clang_msan) $*-input.txt $*-actual-clang-msan.txt
	diff $*-expected.txt $*-actual-clang-msan.txt
	./$(EXE_clang_stack) $*-input.txt $*-actual-clang-stack.txt
	diff $*-expected.txt $*-actual-clang-stack.txt
	@touch $@