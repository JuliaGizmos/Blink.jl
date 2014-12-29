import Base: quit

export active

active(shell::AtomShell) = process_running(shell.proc)

quit(sh::AtomShell) = close(sh.sock)
