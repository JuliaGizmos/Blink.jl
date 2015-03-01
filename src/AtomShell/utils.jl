import Base: quit

export active

active(shell::Shell) = process_running(shell.proc)

quit(sh::Shell) = close(sh.sock)
