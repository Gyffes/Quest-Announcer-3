param([string]$PythonPath = 'python')
$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
& $PythonPath (Join-Path $repoRoot 'tests/run_lua_tests.py')
if ($LASTEXITCODE -ne 0) { throw 'Lua runtime tests failed.' }
