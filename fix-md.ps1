Get-ChildItem -Path . -Recurse -Filter "*.md" | ForEach-Object {
    $file = $_.FullName
    $lines = Get-Content -Path $file -Encoding UTF8

    # 找 YAML 头开始和结束行号
    $startIndex = -1
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -eq '---') {
            $startIndex = $i
            break
        }
    }
    if ($startIndex -eq -1) { return } # 没有yaml头，跳过

    $endIndex = -1
    for ($i = $startIndex + 1; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -eq '---') {
            $endIndex = $i
            break
        }
    }
    if ($endIndex -eq -1) { return } # yaml头不完整，跳过

    # 取出 yaml 头内容（不含分隔线）
    $yamlLines = $lines[($startIndex + 1)..($endIndex - 1)]

    # 替换所有以 published: 开头的行，改成 draft: 并保留后面值和空格
    $yamlLines = $yamlLines | ForEach-Object {
        if ($_ -match '^\s*published\s*:\s*(.+)$') {
            $value = $Matches[1]
            "draft: $value"
        } else {
            $_
        }
    }

    # 重组文件内容
    $newLines = @()
    $newLines += $lines[0..$startIndex]       # --- 起始线
    $newLines += $yamlLines                    # 修改后的yaml内容
    $newLines += $lines[$endIndex..($lines.Count - 1)]  # --- 结束线及正文

    # 写回文件，UTF8无BOM编码
    Set-Content -Path $file -Value $newLines -Encoding utf8

    Write-Host "Processed: $file"
}
