# Purpose: Render class YAML plus shared template content into markdown, plain-text, and DOCX syllabus outputs.
[CmdletBinding()]
param(
    [string]$Class,
    [switch]$All,
    [switch]$DebugRender
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path -Parent $PSScriptRoot
$templatePath = Join-Path $repoRoot 'syllabi/templates/syllabus-template.md'
$classDir = Join-Path $repoRoot 'syllabi/classes'
$outputRoot = Join-Path $repoRoot 'syllabi/output'
$githubOutDir = Join-Path $outputRoot 'github-markdown'
$wordOutDir = Join-Path $outputRoot 'word-friendly-markdown'
$docxOutDir = Join-Path $outputRoot 'word-docx'
$factsOutDir = Join-Path $outputRoot 'facts-plain-text'
$wordRefDir = Join-Path $repoRoot 'syllabi/templates/word-reference'
$highSchoolReferenceDoc = Join-Path $wordRefDir 'high-school-reference.docx'
$middleSchoolReferenceDoc = Join-Path $wordRefDir 'middle-school-reference.docx'

New-Item -ItemType Directory -Path $githubOutDir -Force | Out-Null
New-Item -ItemType Directory -Path $wordOutDir -Force | Out-Null
New-Item -ItemType Directory -Path $docxOutDir -Force | Out-Null
New-Item -ItemType Directory -Path $factsOutDir -Force | Out-Null

$script:PandocPath = $null
$pandocCmd = Get-Command pandoc -ErrorAction SilentlyContinue
if ($pandocCmd) {
    $script:PandocPath = $pandocCmd.Source
}
else {
    $pandocCandidates = @(
        'C:\Program Files\Pandoc\pandoc.exe',
        'C:\Program Files (x86)\Pandoc\pandoc.exe',
        (Join-Path $env:LOCALAPPDATA 'Pandoc\pandoc.exe')
    )
    foreach ($candidate in $pandocCandidates) {
        if (Test-Path -LiteralPath $candidate) {
            $script:PandocPath = $candidate
            break
        }
    }

    if (-not $script:PandocPath) {
        $userPandoc = Get-ChildItem -Path 'C:\Users' -Directory -ErrorAction SilentlyContinue |
            ForEach-Object { Join-Path $_.FullName 'AppData\Local\Pandoc\pandoc.exe' } |
            Where-Object { Test-Path -LiteralPath $_ } |
            Select-Object -First 1
        if ($userPandoc) {
            $script:PandocPath = $userPandoc
        }
    }
}

function Get-GitExecutablePath {
    $gitCmd = Get-Command git -ErrorAction SilentlyContinue
    if ($gitCmd) {
        return $gitCmd.Source
    }

    $gitCandidates = @(
        'C:\Program Files\Git\cmd\git.exe',
        'C:\Program Files\Git\bin\git.exe',
        'C:\Progra~1\Git\cmd\git.exe'
    )
    foreach ($candidate in $gitCandidates) {
        if (Test-Path -LiteralPath $candidate) {
            return $candidate
        }
    }

    return $null
}

function Get-RepositoryWebBaseUrl {
    param(
        [string]$RepoRoot,
        [string]$GitExe
    )

    if (-not $GitExe) {
        return $null
    }

    $originUrl = & $GitExe -C $RepoRoot remote get-url origin 2>$null
    if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($originUrl)) {
        return $null
    }

    $origin = $originUrl.Trim()
    if ($origin -match '^https://github\.com/(?<owner>[^/]+)/(?<repo>[^/.]+?)(?:\.git)?$') {
        return "https://github.com/$($Matches.owner)/$($Matches.repo)"
    }
    if ($origin -match '^git@github\.com:(?<owner>[^/]+)/(?<repo>[^/.]+?)(?:\.git)?$') {
        return "https://github.com/$($Matches.owner)/$($Matches.repo)"
    }

    return $null
}

function Get-RepositoryPublishBranch {
    param(
        [string]$RepoRoot,
        [string]$GitExe
    )

    if (-not $GitExe) {
        return 'main'
    }

    $currentBranch = & $GitExe -C $RepoRoot rev-parse --abbrev-ref HEAD 2>$null
    if ($LASTEXITCODE -eq 0 -and -not [string]::IsNullOrWhiteSpace($currentBranch)) {
        return $currentBranch.Trim()
    }

    return 'main'
}

$gitExe = Get-GitExecutablePath
$repoWebBaseUrl = Get-RepositoryWebBaseUrl -RepoRoot $repoRoot -GitExe $gitExe
$publishBranch = Get-RepositoryPublishBranch -RepoRoot $repoRoot -GitExe $gitExe

function Parse-SimpleYaml {
    param([string]$Path)

    $data = @{}
    $currentListKey = $null

    foreach ($rawLine in Get-Content -LiteralPath $Path) {
        $line = $rawLine.TrimEnd()
        if ([string]::IsNullOrWhiteSpace($line) -or $line.TrimStart().StartsWith('#')) {
            continue
        }

        if ($rawLine -match '^(?<indent>\s*)(?<key>[A-Za-z0-9_]+):\s*(?<value>.*)$' -and $Matches.indent.Length -eq 0) {
            $key = $Matches.key
            $value = $Matches.value.Trim()

            if ([string]::IsNullOrWhiteSpace($value)) {
                $data[$key] = New-Object System.Collections.Generic.List[string]
                $currentListKey = $key
            }
            else {
                if (($value.StartsWith('"') -and $value.EndsWith('"')) -or ($value.StartsWith("'") -and $value.EndsWith("'"))) {
                    $value = $value.Substring(1, $value.Length - 2)
                }
                $data[$key] = $value
                $currentListKey = $null
            }
            continue
        }

        if ($rawLine -match '^\s*-[ \t]*(?<item>.+)$') {
            if (-not $currentListKey) {
                throw "List item found without active key in file: $Path"
            }
            $item = $Matches.item.Trim()
            if (($item.StartsWith('"') -and $item.EndsWith('"')) -or ($item.StartsWith("'") -and $item.EndsWith("'"))) {
                $item = $item.Substring(1, $item.Length - 2)
            }
            $data[$currentListKey].Add($item)
            continue
        }
    }

    return $data
}

function Resolve-Conditionals {
    param(
        [string]$Text,
        [hashtable]$Data
    )

    $pattern = [regex]'(?s)\{%\s*if\s+reading_level\s*==\s*"high-school"\s*%\}(?<ifBlock>.*?)\{%\s*else\s*%\}(?<elseBlock>.*?)\{%\s*endif\s*%\}'
    $result = $Text
    while (($m = $pattern.Match($result)).Success) {
        $replacement = if (($Data['reading_level'] + '') -eq 'high-school') { $m.Groups['ifBlock'].Value } else { $m.Groups['elseBlock'].Value }
        $before = $result.Substring(0, $m.Index)
        $after = $result.Substring($m.Index + $m.Length)
        $result = $before + $replacement + $after
    }
    return $result
}

function Resolve-Loops {
    param(
        [string]$Text,
        [hashtable]$Data
    )

    $pattern = [regex]'(?s)\{%\s*for\s+(?<var>[A-Za-z0-9_]+)\s+in\s+(?<listKey>[A-Za-z0-9_]+)\s*%\}(?<body>.*?)\{%\s*endfor\s*%\}'
    $result = $Text
    while (($m = $pattern.Match($result)).Success) {
        $varName = $m.Groups['var'].Value
        $listKey = $m.Groups['listKey'].Value
        $body = $m.Groups['body'].Value

        $replacement = ''
        if ($Data.ContainsKey($listKey) -and $null -ne $Data[$listKey]) {
            $buffer = New-Object System.Text.StringBuilder
            foreach ($item in $Data[$listKey]) {
                $entry = $body.Replace("{{ $varName }}", [string]$item)
                [void]$buffer.Append($entry)
            }
            $replacement = $buffer.ToString()
        }

        $before = $result.Substring(0, $m.Index)
        $after = $result.Substring($m.Index + $m.Length)
        $result = $before + $replacement + $after
    }
    return $result
}

function Resolve-Includes {
    param(
        [string]$Text,
        [string]$TemplatePath
    )

    $templateDir = Split-Path -Parent $TemplatePath
    $pattern = [regex]'\{%\s*include_relative\s+(?<path>[^%]+?)\s*%\}'
    $result = $Text
    while (($m = $pattern.Match($result)).Success) {
        $relativePath = $m.Groups['path'].Value.Trim()
        $resolvedPath = [System.IO.Path]::GetFullPath((Join-Path $templateDir $relativePath))
        if (-not (Test-Path -LiteralPath $resolvedPath)) {
            throw "Include not found: $relativePath"
        }

        $replacement = [System.IO.File]::ReadAllText($resolvedPath)
        $before = $result.Substring(0, $m.Index)
        $after = $result.Substring($m.Index + $m.Length)
        $result = $before + $replacement + $after
    }
    return $result
}

function Resolve-Placeholders {
    param(
        [string]$Text,
        [hashtable]$Data
    )

    $pattern = [regex]'\{\{\s*(?<key>[A-Za-z0-9_]+)\s*\}\}'
    return $pattern.Replace($Text, {
        param($m)
        $key = $m.Groups['key'].Value
        if (-not $Data.ContainsKey($key)) {
            return ''
        }

        $value = $Data[$key]
        if ($value -is [System.Collections.IEnumerable] -and -not ($value -is [string])) {
            return (($value | ForEach-Object { [string]$_ }) -join ', ')
        }

        return [string]$value
    })
}

function Convert-MarkdownToPlainText {
    param([string]$Markdown)

    $lines = $Markdown -split "`r?`n"
    $plainLines = foreach ($line in $lines) {
        $l = $line
        $l = $l -replace '^#{1,6}\s*', ''
        $l = $l -replace '^\s*-\s+', '- '
        $l = $l -replace '\*\*([^*]+)\*\*', '$1'
        $l = $l -replace '\*([^*]+)\*', '$1'
        $l = $l -replace '`([^`]+)`', '$1'
        $l
    }

    $joined = ($plainLines -join "`n")
    $joined = $joined -replace "`n{3,}", "`n`n"
    return $joined.Trim() + "`n"
}

function Convert-MarkdownToWordFriendly {
    param([string]$Markdown)

    $text = $Markdown -replace "`r`n", "`n"

    # Drop markdownlint-only comments that are not useful in Word.
    $text = [regex]::Replace($text, '(?m)^<!--\s*markdownlint-.*?-->\s*\n?', '')

    # Render email links as plain addresses for cleaner paste into Word.
    $text = [regex]::Replace($text, '\[([^\]]+)\]\(mailto:[^)]+\)', '$1')

    # Collapse spacing where markdown readability inserts extra vertical gaps.
    $text = [regex]::Replace($text, '(?m)(^- .+)\n\n(?=- )', {
        param($m)
        return $m.Groups[1].Value + "`n"
    })
    $text = [regex]::Replace($text, '(?m)^(#{1,6} .+)\n\n', {
        param($m)
        return $m.Groups[1].Value + "`n"
    })
    $text = [regex]::Replace($text, '\n{3,}', "`n`n")

    $body = $text.Trim() + "`n"
    return "<!-- markdownlint-disable MD022 MD032 MD034 -->`n`n" + $body + "`n<!-- markdownlint-enable MD022 MD032 MD034 -->`n"
}

function Render-Class {
    param(
        [string]$ClassYamlPath,
        [string]$TemplatePath,
        [string]$GithubOutDir,
        [string]$WordOutDir,
        [string]$FactsOutDir,
        [string]$RepoRoot,
        [string]$RepoWebBaseUrl,
        [string]$PublishBranch
    )

    $data = Parse-SimpleYaml -Path $ClassYamlPath
    $name = [System.IO.Path]::GetFileNameWithoutExtension($ClassYamlPath)

    # Template helper links for policy-change notices.
    if (-not [string]::IsNullOrWhiteSpace($RepoWebBaseUrl)) {
        $data['syllabus_repo_link'] = "$RepoWebBaseUrl/blob/$PublishBranch/syllabi/output/github-markdown/$name.md"
        $data['rules_readme_link'] = "$RepoWebBaseUrl/blob/$PublishBranch/README.md#shared-rules-baseline-and-change-log"
    }
    else {
        $data['syllabus_repo_link'] = "$name.md"
        $data['rules_readme_link'] = '../../../README.md#shared-rules-baseline-and-change-log'
    }

    $template = [System.IO.File]::ReadAllText($TemplatePath)
    if ($DebugRender) {
        Write-Host "[debug] source if-tags: $(([regex]'\{%\s*if').Matches($template).Count)"
        Write-Host "[debug] source for-tags: $(([regex]'\{%\s*for').Matches($template).Count)"
    }
    $rendered = Resolve-Conditionals -Text $template -Data $data
    if ($DebugRender) {
        Write-Host "[debug] after conditionals if-tags: $(([regex]'\{%\s*if').Matches($rendered).Count)"
    }
    $rendered = Resolve-Loops -Text $rendered -Data $data
    if ($DebugRender) {
        Write-Host "[debug] after loops for-tags: $(([regex]'\{%\s*for').Matches($rendered).Count)"
    }
    $rendered = Resolve-Includes -Text $rendered -TemplatePath $TemplatePath
    if ($DebugRender) {
        Write-Host "[debug] after includes include-tags: $(([regex]'\{%\s*include_relative').Matches($rendered).Count)"
    }
    $rendered = Resolve-Placeholders -Text $rendered -Data $data
    $rendered = ($rendered -replace "`r`n", "`n")
    $rendered = ($rendered -replace "`n{3,}", "`n`n").Trim() + "`n"

    $githubPath = Join-Path $GithubOutDir "$name.md"
    $wordPath = Join-Path $WordOutDir "$name.word.md"
    $docxPath = Join-Path $docxOutDir "$name.docx"
    $factsPath = Join-Path $FactsOutDir "$name.txt"
    $rootSyllabiPath = Join-Path (Join-Path $RepoRoot 'syllabi') "$name.md"

    [System.IO.File]::WriteAllText($githubPath, $rendered)
    [System.IO.File]::WriteAllText($wordPath, (Convert-MarkdownToWordFriendly -Markdown $rendered))
    [System.IO.File]::WriteAllText($factsPath, (Convert-MarkdownToPlainText -Markdown $rendered))

    if ($script:PandocPath) {
        $referenceDoc = if (($data['reading_level'] + '') -eq 'middle-school') { $middleSchoolReferenceDoc } else { $highSchoolReferenceDoc }
        if (Test-Path -LiteralPath $referenceDoc) {
            & $script:PandocPath $wordPath -o $docxPath --reference-doc=$referenceDoc
        }
        else {
            & $script:PandocPath $wordPath -o $docxPath
        }
    }

    if ($name -eq 'physics') {
        [System.IO.File]::WriteAllText($rootSyllabiPath, $rendered)
    }

    [PSCustomObject]@{
        ClassName = $name
        GitHubMarkdown = $githubPath
        WordFriendlyMarkdown = $wordPath
        WordDocx = if ($script:PandocPath) { $docxPath } else { '' }
        PlainText = $factsPath
    }
}

$classFiles = @()
if ($All) {
    $classFiles = Get-ChildItem -LiteralPath $classDir -Filter '*.yaml' | Sort-Object Name
}
elseif (-not [string]::IsNullOrWhiteSpace($Class)) {
    $candidate = Join-Path $classDir "$Class.yaml"
    if (-not (Test-Path -LiteralPath $candidate)) {
        throw "Class YAML not found: $candidate"
    }
    $classFiles = @(Get-Item -LiteralPath $candidate)
}
else {
    throw 'Pass -All or -Class <name>.'
}

$results = foreach ($file in $classFiles) {
    Render-Class -ClassYamlPath $file.FullName -TemplatePath $templatePath -GithubOutDir $githubOutDir -WordOutDir $wordOutDir -FactsOutDir $factsOutDir -RepoRoot $repoRoot -RepoWebBaseUrl $repoWebBaseUrl -PublishBranch $publishBranch
}

$results | Format-Table -AutoSize
