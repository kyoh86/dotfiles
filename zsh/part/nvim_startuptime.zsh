function nvim_startuptime() {
  echo "TOTAL\tMAX\tMIN\tDESC"
  f="$(mktemp)";
  GUISE_NVIM_ADDRESS="" GUISE_VIM_ADDRESS="" nvim --startuptime "$f" -c quit >/dev/null 2>&1;
  cat "$f" | perl -ne 'if (/^(\d{3,}\.\d{3}) +(\d{3,}\.\d{3})(?: +(\d{3,}\.\d{3}))?: *(.*)$/) { print "$1\t$2\t$3\t$4\n" }';
  rm -f "$f" >/dev/null 2>&1
}
