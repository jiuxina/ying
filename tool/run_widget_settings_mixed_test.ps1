# Runs a complex mixed matrix of widget settings on the Android emulator.
param(
    [string]$Serial = 'emulator-5556',
    [string]$OutputRoot = 'F:\xm\ying\outputs\widget-mixed-test',
    [string]$ApkPath = 'F:\xm\ying\daymark\build\app\outputs\flutter-apk\app-debug.apk',
    [int]$MaxScenarios = 0,
    [int]$StartIndex = 1,
    [int]$EndIndex = 0,
    [switch]$SkipInstall,
    [switch]$FontTextOnly,
    [switch]$EveryElement
)

$ErrorActionPreference = 'Stop'
$adb = 'adb'

function Invoke-Adb {
    param([string[]]$ArgsList)
    & $adb -s $Serial @ArgsList
    if ($LASTEXITCODE -ne 0) {
        throw "adb failed: $($ArgsList -join ' ')"
    }
}

function New-PrefsXml {
    param(
        [hashtable]$Settings,
        [string]$EventsJson
    )
    $sb = [System.Text.StringBuilder]::new()
    [void]$sb.AppendLine("<?xml version='1.0' encoding='utf-8' standalone='yes' ?>")
    [void]$sb.AppendLine('<map>')
    foreach ($entry in $Settings.GetEnumerator() | Sort-Object Name) {
        $key = 'flutter.' + $entry.Key
        $value = $entry.Value
        $escapedKey = [System.Security.SecurityElement]::Escape($key)
        if ($value -is [bool]) {
            $text = if ($value) { 'true' } else { 'false' }
            [void]$sb.AppendLine("    <boolean name=`"$escapedKey`" value=`"$text`" />")
        } elseif ($value -is [double] -or $value -is [single]) {
            $text = ([double]$value).ToString([Globalization.CultureInfo]::InvariantCulture)
            [void]$sb.AppendLine("    <double name=`"$escapedKey`" value=`"$text`" />")
        } elseif ($value -is [int] -or $value -is [long]) {
            [void]$sb.AppendLine("    <long name=`"$escapedKey`" value=`"$value`" />")
        } else {
            $text = [System.Security.SecurityElement]::Escape([string]$value)
            [void]$sb.AppendLine("    <string name=`"$escapedKey`">$text</string>")
        }
    }
    $escapedEvents = [System.Security.SecurityElement]::Escape($EventsJson)
    [void]$sb.AppendLine("    <string name=`"flutter.countdown_events_v1`">$escapedEvents</string>")
    [void]$sb.AppendLine('</map>')
    return $sb.ToString()
}

function ConvertTo-HexInt64 {
    param([string]$Hex)
    return [Convert]::ToInt64($Hex, 16)
}

function New-ElementStylesJson {
    param([hashtable]$Styles)
    if ($null -eq $Styles -or $Styles.Count -eq 0) {
        return '{}'
    }
    return ConvertTo-Json $Styles -Depth 6 -Compress
}

function Get-BaseSettings {
    $blue = ConvertTo-HexInt64 'FF0F766E'
    return @{
        onboarding_completed_v1 = $true
        sponsor_unlocked = $true
        auto_check_update = $false
        theme_mode = 'system'
        widget_color = $blue
        widget_font_scale = 1.0
        widget_show_note = $true
        widget_show_category = $true
        event_sort_mode = 'distance'
        reduce_transparency = $false
        reduce_motion = $false
        avatar_path = ''
        widget_style = 'card'
        widget_background_path = ''
        widget_background_brightness = 1.0
        widget_background_blur = 0.0
        widget_unit_text = ''
        widget_show_icon = $false
        widget_show_progress = $false
        widget_show_precise_time = $false
        widget_show_lunar_week = $false
        widget_mystery_mode = $false
        widget_quote_mode = $false
        widget_urgent_highlight = $false
        widget_list_mode = $false
        widget_font_family = 'system'
        widget_text_font_family = 'system'
        widget_digit_font_path = ''
        widget_text_font_path = ''
        widget_text_outline = $false
        widget_wallpaper_color = -1
        widget_wallpaper_dark_color = -1
        widget_wallpaper_text_color = -1
        widget_element_styles = '{}'
        widget_vertical_align = 'center'
        widget_content_margin = 16.0
    }
}

function Get-Scenarios {
    $blue = ConvertTo-HexInt64 'FF0F766E'
    $indigo = ConvertTo-HexInt64 'FF4F46E5'
    $pink = ConvertTo-HexInt64 'FFDB2777'
    $mint = ConvertTo-HexInt64 'FF16A085'
    $gray = ConvertTo-HexInt64 'FF636366'

    $scenarioList = [System.Collections.Generic.List[object]]::new()
    function Add-Scenario {
        param(
            [string]$Name,
            [hashtable]$Overrides,
            [hashtable]$ElementStyles
        )
        $settings = (Get-BaseSettings)
        foreach ($entry in $Overrides.GetEnumerator()) {
            $settings[$entry.Key] = $entry.Value
        }
        if ($null -ne $ElementStyles) {
            $settings.widget_element_styles = New-ElementStylesJson $ElementStyles
        }
        $scenarioList.Add(@{ name = $Name; settings = $settings }) | Out-Null
    }

    Add-Scenario 's01-card-blue-all-on' @{
        widget_show_icon = $true
        widget_show_progress = $true
        widget_show_precise_time = $true
        widget_show_lunar_week = $true
        widget_urgent_highlight = $true
    }
    Add-Scenario 's02-sticker-pink-200' @{
        widget_style = 'sticker'
        widget_color = $pink
        widget_font_scale = 2.0
        widget_show_icon = $true
        widget_show_note = $true
        widget_show_category = $true
    }
    Add-Scenario 's03-photo-mint-150' @{
        widget_style = 'photo'
        widget_color = $mint
        widget_font_scale = 1.5
        widget_show_progress = $true
    }
    Add-Scenario 's04-glass-indigo-50' @{
        widget_style = 'glass'
        widget_color = $indigo
        widget_font_scale = 0.5
        widget_show_lunar_week = $true
        widget_show_precise_time = $true
    }
    Add-Scenario 's05-polaroid-gray-125' @{
        widget_style = 'polaroid'
        widget_color = $gray
        widget_font_scale = 1.25
        widget_show_note = $false
        widget_show_icon = $true
    }
    Add-Scenario 's06-neon-blue-200' @{
        widget_style = 'neon'
        widget_color = $blue
        widget_font_scale = 2.0
        widget_urgent_highlight = $true
        widget_show_progress = $true
    }
    Add-Scenario 's07-pixel-pink-150' @{
        widget_style = 'pixel'
        widget_color = $pink
        widget_font_scale = 1.5
        widget_show_precise_time = $true
    }
    Add-Scenario 's08-minimal-mint-50' @{
        widget_style = 'minimal'
        widget_color = $mint
        widget_font_scale = 0.5
        widget_show_lunar_week = $true
    }
    Add-Scenario 's09-envelope-gray-200' @{
        widget_style = 'envelope'
        widget_color = $gray
        widget_font_scale = 2.0
        widget_quote_mode = $true
    }
    Add-Scenario 's10-capsule-blue-100' @{
        widget_style = 'capsule'
        widget_color = $blue
        widget_show_progress = $true
    }
    Add-Scenario 's11-crt-mint-150' @{
        widget_style = 'crt'
        widget_color = $mint
        widget_font_scale = 1.5
        widget_text_outline = $true
        widget_font_family = 'mono'
    }
    Add-Scenario 's12-neonsign-pink-200' @{
        widget_style = 'neonSign'
        widget_color = $pink
        widget_font_scale = 2.0
        widget_urgent_highlight = $true
    }
    Add-Scenario 's13-pixelhealth-indigo-125' @{
        widget_style = 'pixelHealth'
        widget_color = $indigo
        widget_font_scale = 1.25
        widget_show_progress = $true
        widget_show_precise_time = $true
        widget_show_lunar_week = $true
        widget_show_icon = $true
    }
    Add-Scenario 's14-mirror-gray-50' @{
        widget_style = 'mirror'
        widget_color = $gray
        widget_font_scale = 0.5
        widget_quote_mode = $true
    }
    Add-Scenario 's15-mystery-precise-progress' @{
        widget_mystery_mode = $true
        widget_show_precise_time = $true
        widget_show_progress = $true
        widget_show_lunar_week = $true
        widget_show_icon = $true
        widget_urgent_highlight = $true
    }
    Add-Scenario 's16-list-all-on-weeks-margin4' @{
        widget_list_mode = $true
        widget_quote_mode = $true
        widget_show_icon = $true
        widget_show_progress = $true
        widget_show_precise_time = $true
        widget_show_lunar_week = $true
        widget_urgent_highlight = $true
        widget_unit_text = 'weeks'
        widget_content_margin = 4.0
        widget_font_scale = 2.0
    }
    Add-Scenario 's17-quote-no-note-urgent' @{
        widget_style = 'glass'
        widget_quote_mode = $true
        widget_show_note = $false
        widget_show_category = $false
        widget_urgent_highlight = $true
    }
    Add-Scenario 's18-icon-note-no-category' @{
        widget_style = 'sticker'
        widget_show_icon = $true
        widget_show_note = $true
        widget_show_category = $false
        widget_show_precise_time = $true
    }
    Add-Scenario 's19-weeks-precise-progress' @{
        widget_style = 'minimal'
        widget_unit_text = 'weeks'
        widget_show_precise_time = $true
        widget_show_progress = $true
    }
    Add-Scenario 's20-remaining-countup' @{
        widget_style = 'pixel'
        widget_unit_text = 'remaining'
        widget_urgent_highlight = $true
    }
    Add-Scenario 's21-urgent-custom-colors' @{
        widget_style = 'neon'
        widget_urgent_highlight = $true
        widget_show_note = $false
    } @{
        title = @{ visible = 'show'; size = 'large'; sizeScale = 1.4; weight = 800; colorMode = 'custom'; color = ([Convert]::ToInt64('FFFF5A5F', 16)); align = 'center' }
        days = @{ visible = 'show'; size = 'xlarge'; sizeScale = 1.8; weight = 900; colorMode = 'custom'; color = ([Convert]::ToInt64('FFFFD60A', 16)); align = 'center' }
        unit = @{ visible = 'show'; size = 'normal'; sizeScale = 1.0; weight = 600; colorMode = 'custom'; color = ([Convert]::ToInt64('FF22D3EE', 16)); align = 'start' }
    }
    Add-Scenario 's22-crt-outline-mono-hand' @{
        widget_style = 'crt'
        widget_text_outline = $true
        widget_font_family = 'mono'
        widget_text_font_family = 'hand'
        widget_show_precise_time = $true
        widget_show_lunar_week = $true
    }
    Add-Scenario 's23-hide-title-days' @{
        widget_show_note = $true
        widget_show_category = $false
    } @{
        title = @{ visible = 'hide' }
        days = @{ visible = 'hide' }
        unit = @{ visible = 'show'; size = 'xlarge'; sizeScale = 1.6; weight = 700 }
        note = @{ visible = 'show'; size = 'large'; sizeScale = 1.3; align = 'center' }
    }
    Add-Scenario 's24-xlarge-200-margin4-top' @{
        widget_style = 'neon'
        widget_font_scale = 2.0
        widget_content_margin = 4.0
        widget_vertical_align = 'top'
        widget_show_icon = $true
        widget_show_precise_time = $true
    } @{
        title = @{ size = 'xlarge'; sizeScale = 2.0; weight = 900 }
        days = @{ size = 'xlarge'; sizeScale = 2.0; weight = 900 }
        unit = @{ size = 'large'; sizeScale = 1.5; weight = 700 }
        note = @{ size = 'large'; sizeScale = 1.5; weight = 700 }
    }
    Add-Scenario 's25-small-50-margin40-bottom' @{
        widget_style = 'minimal'
        widget_font_scale = 0.5
        widget_content_margin = 40.0
        widget_vertical_align = 'bottom'
        widget_show_lunar_week = $true
    } @{
        title = @{ size = 'small'; sizeScale = 0.8 }
        days = @{ size = 'small'; sizeScale = 0.8 }
        unit = @{ size = 'small'; sizeScale = 0.8 }
    }
    Add-Scenario 's26-list-top-margin4' @{
        widget_list_mode = $true
        widget_vertical_align = 'top'
        widget_content_margin = 4.0
        widget_font_scale = 1.5
        widget_show_icon = $true
        widget_show_progress = $true
        widget_show_precise_time = $true
        widget_show_lunar_week = $true
        widget_urgent_highlight = $true
    }
    Add-Scenario 's27-envelope-bottom-hide-buttons' @{
        widget_style = 'envelope'
        widget_vertical_align = 'bottom'
        widget_quote_mode = $true
    } @{
        prevButton = @{ visible = 'hide' }
        nextButton = @{ visible = 'hide' }
    }
    Add-Scenario 's28-photo-bright-blur' @{
        widget_style = 'photo'
        widget_background_path = '/data/user/0/com.jiuxina.ying/app_flutter/widget_background.jpg'
        widget_background_brightness = 0.6
        widget_background_blur = 8.0
        widget_font_scale = 1.5
        widget_show_progress = $true
        widget_show_lunar_week = $true
    }
    Add-Scenario 's29-wallpaper-neon' @{
        widget_style = 'neon'
        widget_wallpaper_color = ([Convert]::ToInt64('FF123456', 16))
        widget_wallpaper_dark_color = ([Convert]::ToInt64('FF0A0F1E', 16))
        widget_wallpaper_text_color = ([Convert]::ToInt64('FFFFE9A0', 16))
        widget_font_scale = 1.25
    }
    Add-Scenario 's30-pixelhealth-full-meta' @{
        widget_style = 'pixelHealth'
        widget_show_progress = $true
        widget_show_precise_time = $true
        widget_show_lunar_week = $true
        widget_show_icon = $true
        widget_show_note = $true
        widget_show_category = $true
        widget_urgent_highlight = $true
        widget_font_scale = 1.75
    }
    Add-Scenario 's31-mirror-quote-list-margin4' @{
        widget_style = 'mirror'
        widget_quote_mode = $true
        widget_list_mode = $true
        widget_content_margin = 4.0
        widget_font_scale = 1.5
    }
    Add-Scenario 's32-crt-outline-mono-weeks' @{
        widget_style = 'crt'
        widget_text_outline = $true
        widget_font_family = 'mono'
        widget_unit_text = 'weeks'
        widget_show_progress = $true
        widget_show_lunar_week = $true
    }
    Add-Scenario 's33-minimal-days-only-center' @{
        widget_style = 'minimal'
        widget_show_note = $false
        widget_show_category = $false
        widget_show_precise_time = $true
    } @{
        category = @{ visible = 'hide' }
        title = @{ visible = 'hide' }
        days = @{ visible = 'show'; size = 'xlarge'; sizeScale = 2.0; weight = 900; colorMode = 'custom'; color = ([Convert]::ToInt64('FFFFFFFF', 16)); align = 'center' }
        unit = @{ visible = 'show'; size = 'large'; sizeScale = 1.4; align = 'center' }
        note = @{ visible = 'hide' }
        precise = @{ visible = 'show'; size = 'normal'; sizeScale = 1.0; align = 'center' }
    }
    Add-Scenario 's34-card-all-element-styles' @{
        widget_show_icon = $true
        widget_show_progress = $true
        widget_show_precise_time = $true
        widget_show_lunar_week = $true
        widget_urgent_highlight = $true
    } @{
        category = @{ visible = 'show'; size = 'normal'; sizeScale = 1.0; weight = 500; colorMode = 'secondary'; align = 'start' }
        holidayBadge = @{ visible = 'show'; size = 'small'; sizeScale = 0.9; weight = 600; colorMode = 'custom'; color = ([Convert]::ToInt64('FFFFD60A', 16)); align = 'start' }
        title = @{ visible = 'show'; size = 'large'; sizeScale = 1.5; weight = 800; colorMode = 'custom'; color = ([Convert]::ToInt64('FFFF8A80', 16)); align = 'center' }
        days = @{ visible = 'show'; size = 'xlarge'; sizeScale = 1.9; weight = 900; colorMode = 'primary'; align = 'end' }
        unit = @{ visible = 'show'; size = 'normal'; sizeScale = 1.1; weight = 500; colorMode = 'secondary'; align = 'end' }
        note = @{ visible = 'show'; size = 'large'; sizeScale = 1.3; weight = 600; colorMode = 'custom'; color = ([Convert]::ToInt64('FFA5D6A7', 16)); align = 'start' }
        precise = @{ visible = 'show'; size = 'normal'; sizeScale = 1.2; weight = 500; colorMode = 'custom'; color = ([Convert]::ToInt64('FF81D4FA', 16)); align = 'center' }
        dateInfo = @{ visible = 'show'; size = 'small'; sizeScale = 0.95; weight = 500; colorMode = 'secondary'; align = 'start' }
        progress = @{ visible = 'show'; size = 'normal'; sizeScale = 1.0; weight = 0; colorMode = 'custom'; color = ([Convert]::ToInt64('FF64B5F6', 16)); align = 'start' }
        icon = @{ visible = 'show'; size = 'large'; sizeScale = 1.5; weight = 0; colorMode = 'primary'; align = 'start' }
        prevButton = @{ visible = 'show'; size = 'normal'; sizeScale = 1.2; weight = 0; colorMode = 'custom'; color = ([Convert]::ToInt64('FFFFFFFF', 16)); align = 'start' }
        nextButton = @{ visible = 'show'; size = 'normal'; sizeScale = 1.2; weight = 0; colorMode = 'custom'; color = ([Convert]::ToInt64('FFFFFFFF', 16)); align = 'start' }
    }
    Add-Scenario 's35-envelope-list-margin4-scale200' @{
        widget_style = 'envelope'
        widget_list_mode = $true
        widget_content_margin = 4.0
        widget_font_scale = 2.0
        widget_quote_mode = $true
        widget_mystery_mode = $true
    }
    Add-Scenario 's36-capsule-mystery-precise-progress-urgent' @{
        widget_style = 'capsule'
        widget_mystery_mode = $true
        widget_show_precise_time = $true
        widget_show_progress = $true
        widget_urgent_highlight = $true
        widget_show_lunar_week = $true
        widget_unit_text = 'only'
    }
    Add-Scenario 's37-reset-defaults' @{}
    return $scenarioList.ToArray()
}

function Get-FontTextScenarios {
    $blue = ConvertTo-HexInt64 'FF0F766E'
    $pink = ConvertTo-HexInt64 'FFDB2777'
    $mint = ConvertTo-HexInt64 'FF16A085'
    $red = ConvertTo-HexInt64 'FFFF5A5F'
    $yellow = ConvertTo-HexInt64 'FFFFD60A'
    $cyan = ConvertTo-HexInt64 'FF22D3EE'
    $white = ConvertTo-HexInt64 'FFFFFFFF'

    $scenarioList = [System.Collections.Generic.List[object]]::new()
    function Add-FontScenario {
        param(
            [string]$Name,
            [hashtable]$Overrides,
            [hashtable]$ElementStyles
        )
        $settings = (Get-BaseSettings)
        foreach ($entry in $Overrides.GetEnumerator()) {
            $settings[$entry.Key] = $entry.Value
        }
        if ($null -ne $ElementStyles) {
            $settings.widget_element_styles = New-ElementStylesJson $ElementStyles
        }
        $scenarioList.Add(@{ name = $Name; settings = $settings }) | Out-Null
    }

    Add-FontScenario 'f01-system-baseline' @{
        widget_show_icon = $true
        widget_show_progress = $true
        widget_show_precise_time = $true
        widget_show_lunar_week = $true
        widget_urgent_highlight = $true
    }
    Add-FontScenario 'f02-mono-200' @{
        widget_font_family = 'mono'
        widget_font_scale = 2.0
        widget_show_icon = $true
        widget_show_progress = $true
        widget_show_precise_time = $true
        widget_show_lunar_week = $true
        widget_urgent_highlight = $true
    }
    Add-FontScenario 'f03-pixel-150-outline' @{
        widget_font_family = 'pixel'
        widget_text_outline = $true
        widget_font_scale = 1.5
        widget_show_icon = $true
        widget_show_note = $true
        widget_show_category = $true
    }
    Add-FontScenario 'f04-hand-125-fallback-text' @{
        widget_font_family = 'hand'
        widget_text_font_family = 'hand'
        widget_font_scale = 1.25
        widget_show_lunar_week = $true
        widget_quote_mode = $true
    }
    Add-FontScenario 'f05-minimal-50' @{
        widget_style = 'minimal'
        widget_font_scale = 0.5
        widget_show_note = $false
        widget_show_category = $false
        widget_show_precise_time = $true
    }
    Add-FontScenario 'f06-crt-mono-outline' @{
        widget_style = 'crt'
        widget_font_family = 'mono'
        widget_text_outline = $true
        widget_font_scale = 1.75
        widget_show_precise_time = $true
        widget_show_lunar_week = $true
    }
    Add-FontScenario 'f07-title-days-xlarge-900' @{
        widget_font_scale = 1.5
        widget_content_margin = 8.0
        widget_show_precise_time = $true
        widget_show_lunar_week = $true
    } @{
        title = @{ visible = 'show'; size = 'xlarge'; sizeScale = 2.0; weight = 900; colorMode = 'custom'; color = $red; align = 'center' }
        days = @{ visible = 'show'; size = 'xlarge'; sizeScale = 2.0; weight = 900; colorMode = 'custom'; color = $yellow; align = 'center' }
        unit = @{ visible = 'show'; size = 'large'; sizeScale = 1.5; weight = 800; colorMode = 'custom'; color = $cyan; align = 'center' }
    }
    Add-FontScenario 'f08-hide-title-days' @{
        widget_font_scale = 2.0
        widget_content_margin = 4.0
        widget_show_note = $true
        widget_show_precise_time = $true
        widget_show_lunar_week = $true
        widget_show_progress = $true
    } @{
        title = @{ visible = 'hide' }
        days = @{ visible = 'hide' }
        unit = @{ visible = 'show'; size = 'xlarge'; sizeScale = 1.8; weight = 900 }
        note = @{ visible = 'show'; size = 'large'; sizeScale = 1.4; align = 'center' }
        precise = @{ visible = 'show'; size = 'large'; sizeScale = 1.4; weight = 700 }
        dateInfo = @{ visible = 'show'; size = 'large'; sizeScale = 1.3 }
    }
    Add-FontScenario 'f09-all-elements-custom' @{
        widget_font_scale = 1.25
        widget_show_icon = $true
        widget_show_progress = $true
        widget_show_precise_time = $true
        widget_show_lunar_week = $true
        widget_urgent_highlight = $true
    } @{
        category = @{ visible = 'show'; size = 'normal'; sizeScale = 1.0; weight = 500; colorMode = 'custom'; color = $cyan; align = 'start' }
        title = @{ visible = 'show'; size = 'large'; sizeScale = 1.6; weight = 800; colorMode = 'custom'; color = $red; align = 'center' }
        days = @{ visible = 'show'; size = 'xlarge'; sizeScale = 1.9; weight = 900; colorMode = 'custom'; color = $yellow; align = 'end' }
        unit = @{ visible = 'show'; size = 'normal'; sizeScale = 1.2; weight = 600; colorMode = 'custom'; color = $white; align = 'end' }
        note = @{ visible = 'show'; size = 'large'; sizeScale = 1.3; weight = 500; colorMode = 'custom'; color = $mint; align = 'start' }
        precise = @{ visible = 'show'; size = 'normal'; sizeScale = 1.2; weight = 500; colorMode = 'custom'; color = $cyan; align = 'center' }
        dateInfo = @{ visible = 'show'; size = 'small'; sizeScale = 0.9; weight = 500; colorMode = 'custom'; color = $white; align = 'start' }
        progress = @{ visible = 'show'; size = 'normal'; sizeScale = 1.0; weight = 0; colorMode = 'custom'; color = $pink; align = 'start' }
        icon = @{ visible = 'show'; size = 'large'; sizeScale = 1.5; weight = 0; colorMode = 'primary'; align = 'start' }
    }
    Add-FontScenario 'f10-list-rows-custom' @{
        widget_list_mode = $true
        widget_font_scale = 1.5
        widget_content_margin = 4.0
        widget_quote_mode = $true
        widget_show_icon = $true
        widget_show_progress = $true
        widget_show_precise_time = $true
        widget_show_lunar_week = $true
        widget_urgent_highlight = $true
    } @{
        listHeader = @{ visible = 'show'; size = 'large'; sizeScale = 1.6; weight = 800; colorMode = 'custom'; color = $yellow; align = 'center' }
        rowTitle = @{ visible = 'show'; size = 'large'; sizeScale = 1.5; weight = 700; colorMode = 'custom'; color = $red; align = 'start' }
        rowSubtitle = @{ visible = 'show'; size = 'normal'; sizeScale = 1.2; weight = 500; colorMode = 'custom'; color = $cyan; align = 'start' }
        rowDays = @{ visible = 'show'; size = 'xlarge'; sizeScale = 1.8; weight = 900; colorMode = 'custom'; color = $white; align = 'end' }
        rowUnit = @{ visible = 'show'; size = 'normal'; sizeScale = 1.2; weight = 600; colorMode = 'custom'; color = $mint; align = 'end' }
    }
    Add-FontScenario 'f11-hide-everything-near-empty' @{
        widget_font_scale = 2.0
        widget_content_margin = 4.0
        widget_show_note = $false
        widget_show_category = $false
        widget_show_precise_time = $true
        widget_show_lunar_week = $true
    } @{
        category = @{ visible = 'hide' }
        title = @{ visible = 'hide' }
        days = @{ visible = 'hide' }
        unit = @{ visible = 'hide' }
        note = @{ visible = 'hide' }
        precise = @{ visible = 'show'; size = 'xlarge'; sizeScale = 1.8; weight = 900; align = 'center' }
        dateInfo = @{ visible = 'show'; size = 'large'; sizeScale = 1.4; weight = 700; align = 'center' }
    }
    Add-FontScenario 'f12-neonsign-mixed' @{
        widget_style = 'neonSign'
        widget_font_family = 'hand'
        widget_text_outline = $true
        widget_quote_mode = $true
        widget_urgent_highlight = $true
        widget_font_scale = 2.0
    }
    Add-FontScenario 'f13-pixelhealth-full' @{
        widget_style = 'pixelHealth'
        widget_font_family = 'mono'
        widget_font_scale = 1.75
        widget_show_icon = $true
        widget_show_progress = $true
        widget_show_precise_time = $true
        widget_show_lunar_week = $true
        widget_show_note = $true
        widget_show_category = $true
        widget_urgent_highlight = $true
    } @{
        title = @{ visible = 'show'; size = 'large'; sizeScale = 1.6; weight = 900; colorMode = 'custom'; color = $yellow; align = 'center' }
        days = @{ visible = 'show'; size = 'xlarge'; sizeScale = 1.9; weight = 900; colorMode = 'custom'; color = $white; align = 'center' }
    }
    Add-FontScenario 'f14-envelope-mystery-precise' @{
        widget_style = 'envelope'
        widget_mystery_mode = $true
        widget_show_precise_time = $true
        widget_quote_mode = $true
        widget_font_scale = 2.0
        widget_content_margin = 4.0
    } @{
        prevButton = @{ visible = 'hide' }
        nextButton = @{ visible = 'hide' }
    }
    Add-FontScenario 'f15-mirror-hand-outline' @{
        widget_style = 'mirror'
        widget_font_family = 'hand'
        widget_text_outline = $true
        widget_font_scale = 1.5
        widget_show_progress = $true
        widget_show_lunar_week = $true
    }
    Add-FontScenario 'f16-missing-font-paths' @{
        widget_font_family = 'mono'
        widget_text_font_family = 'catalog:missing'
        widget_digit_font_path = '/data/user/0/com.jiuxina.ying/app_flutter/missing-digits.ttf'
        widget_text_font_path = '/data/user/0/com.jiuxina.ying/app_flutter/missing-text.ttf'
        widget_text_outline = $true
        widget_font_scale = 1.25
        widget_show_precise_time = $true
        widget_show_lunar_week = $true
    }
    Add-FontScenario 'f17-capsule-mono-precise' @{
        widget_style = 'capsule'
        widget_font_family = 'mono'
        widget_font_scale = 1.25
        widget_show_precise_time = $true
        widget_show_lunar_week = $true
        widget_show_progress = $true
    }
    Add-FontScenario 'f18-minimal-days-only-center' @{
        widget_style = 'minimal'
        widget_font_scale = 1.75
        widget_show_note = $false
        widget_show_category = $false
        widget_show_precise_time = $true
    } @{
        category = @{ visible = 'hide' }
        title = @{ visible = 'hide' }
        days = @{ visible = 'show'; size = 'xlarge'; sizeScale = 2.0; weight = 900; colorMode = 'custom'; color = $white; align = 'center' }
        unit = @{ visible = 'show'; size = 'large'; sizeScale = 1.5; weight = 700; align = 'center' }
        note = @{ visible = 'hide' }
        precise = @{ visible = 'show'; size = 'normal'; sizeScale = 1.2; weight = 500; align = 'center' }
    }
    return $scenarioList.ToArray()
}

function Get-EveryElementScenarios {
    $textIds = @(
        'category',
        'holidayBadge',
        'title',
        'days',
        'unit',
        'note',
        'precise',
        'dateInfo',
        'progress',
        'icon',
        'listHeader',
        'rowTitle',
        'rowSubtitle',
        'rowDays',
        'rowUnit',
        'empty'
    )
    $buttonIds = @('prevButton', 'nextButton')
    $nonTextIds = @('holidayBadge', 'progress', 'icon', 'empty')
    $alignableIds = @(
        'category',
        'title',
        'days',
        'note',
        'precise',
        'dateInfo',
        'empty',
        'listHeader',
        'rowTitle',
        'rowSubtitle'
    )
    $yellow = ConvertTo-HexInt64 'FFFFD60A'
    $scenarioList = [System.Collections.Generic.List[object]]::new()

    function Add-ElementScenario {
        param(
            [string]$Name,
            [hashtable]$Overrides,
            [hashtable]$ElementStyles
        )
        $settings = Get-BaseSettings
        foreach ($entry in $Overrides.GetEnumerator()) {
            $settings[$entry.Key] = $entry.Value
        }
        $settings.widget_element_styles = New-ElementStylesJson $ElementStyles
        $scenarioList.Add(@{ name = $Name; settings = $settings }) | Out-Null
    }

    $index = 0
    foreach ($id in $textIds) {
        $index++
        $name = ('e{0:D2}-{1}' -f $index, $id)
        $style = @{
            visible = 'show'
            sizeScale = 1.4
            colorMode = 'custom'
            color = $yellow
        }
        if ($id -notin $nonTextIds) {
            $style.weight = 700
        }
        if ($id -in $alignableIds) {
            $style.align = 'center'
        }
        $overrides = @{
            widget_show_icon = $true
            widget_show_progress = $true
            widget_show_precise_time = $true
            widget_show_lunar_week = $true
            widget_urgent_highlight = $true
            widget_show_note = $true
            widget_show_category = $true
        }
        if ($id -in @('listHeader', 'rowTitle', 'rowSubtitle', 'rowDays', 'rowUnit', 'empty')) {
            $overrides.widget_list_mode = $true
        }
        Add-ElementScenario $name $overrides @{ $id = $style }
    }

    foreach ($id in $buttonIds) {
        $index++
        $name = ('e{0:D2}-{1}' -f $index, $id)
        Add-ElementScenario $name @{} @{ $id = @{ visible = 'hide' } }
    }

    $index++
    $allStyles = @{}
    foreach ($id in $textIds) {
        $style = @{
            visible = 'show'
            sizeScale = 1.6
            colorMode = 'custom'
            color = $yellow
        }
        if ($id -notin $nonTextIds) {
            $style.weight = 900
        }
        if ($id -in $alignableIds) {
            $style.align = 'center'
        }
        $allStyles[$id] = $style
    }
    foreach ($id in $buttonIds) {
        $allStyles[$id] = @{ visible = 'hide' }
    }
    Add-ElementScenario ('e{0:D2}-all-combined' -f $index) @{
        widget_show_icon = $true
        widget_show_progress = $true
        widget_show_precise_time = $true
        widget_show_lunar_week = $true
        widget_urgent_highlight = $true
        widget_show_note = $true
        widget_show_category = $true
        widget_list_mode = $true
        widget_font_scale = 1.5
        widget_content_margin = 4.0
    } $allStyles

    return $scenarioList.ToArray()
}

function Get-EventsJson {
    $now = [DateTime]::Now
    $events = @(
        @{
            id = 'test-holiday-exam'
            title = '高考倒计时'
            targetDate = $now.AddDays(30).ToString('yyyy-MM-ddTHH:mm:ss.fffK')
            category = '学习'
            note = '努力加油'
            icon = '🎓'
            direction = 'auto'
            reminders = @()
            isAllDay = $true
            isCompleted = $false
            isPinned = $false
            repeatType = 'none'
            createdAt = $now.ToString('yyyy-MM-ddTHH:mm:ss.fffK')
        },
        @{
            id = 'test-delivery'
            title = '项目交付'
            targetDate = $now.AddDays(7).ToString('yyyy-MM-ddTHH:mm:ss.fffK')
            category = '工作'
            note = ''
            icon = '💼'
            direction = 'auto'
            reminders = @()
            isAllDay = $true
            isCompleted = $false
            isPinned = $false
            repeatType = 'none'
            createdAt = $now.ToString('yyyy-MM-ddTHH:mm:ss.fffK')
        },
        @{
            id = 'test-anniversary'
            title = '恋爱纪念日'
            targetDate = $now.AddDays(-10).ToString('yyyy-MM-ddTHH:mm:ss.fffK')
            category = '纪念日'
            note = '在一起第 N 天'
            icon = '❤️'
            direction = 'countup'
            reminders = @()
            isAllDay = $true
            isCompleted = $false
            isPinned = $false
            repeatType = 'none'
            createdAt = $now.ToString('yyyy-MM-ddTHH:mm:ss.fffK')
        },
        @{
            id = 'test-today'
            title = '今天的约定'
            targetDate = $now.ToString('yyyy-MM-ddTHH:mm:ss.fffK')
            category = '生活'
            note = '就是今天'
            icon = '🎉'
            direction = 'auto'
            reminders = @()
            isAllDay = $true
            isCompleted = $false
            isPinned = $false
            repeatType = 'none'
            createdAt = $now.ToString('yyyy-MM-ddTHH:mm:ss.fffK')
        },
        @{
            id = 'test-trip'
            title = '明年环岛旅行'
            targetDate = $now.AddDays(365).ToString('yyyy-MM-ddTHH:mm:ss.fffK')
            category = '旅行'
            note = '办好护照'
            icon = '✈️'
            direction = 'auto'
            reminders = @()
            isAllDay = $true
            isCompleted = $false
            isPinned = $true
            repeatType = 'none'
            createdAt = $now.ToString('yyyy-MM-ddTHH:mm:ss.fffK')
        }
    )
    return ConvertTo-Json $events -Depth 8 -Compress
}

function Reset-App {
    Invoke-Adb @('shell', 'am', 'force-stop', 'com.jiuxina.ying')
    Start-Sleep -Milliseconds 500
    Invoke-Adb @('shell', 'am', 'start', '-n', 'com.jiuxina.ying/.MainActivity')
    Start-Sleep -Seconds 4
}

function Open-WidgetSettings {
    Invoke-Adb @('shell', 'input', 'tap', '960', '156')
    Start-Sleep -Seconds 1
    Invoke-Adb @('shell', 'input', 'tap', '540', '1060')
    Start-Sleep -Seconds 5
}

function Scroll-To-Bottom {
    for ($i = 0; $i -lt 14; $i++) {
        Invoke-Adb @('shell', 'input', 'swipe', '540', '1650', '540', '450', '250')
        Start-Sleep -Milliseconds 120
    }
    Start-Sleep -Seconds 1
}

function Save-Screen {
    param([string]$DevicePath, [string]$LocalPath)
    Invoke-Adb @('shell', 'screencap', '-p', $DevicePath)
    Invoke-Adb @('pull', $DevicePath, $LocalPath) | Out-Null
}

function Save-UiDump {
    param([string]$DevicePath, [string]$LocalPath)
    Invoke-Adb @('shell', 'uiautomator', 'dump', $DevicePath) | Out-Null
    Invoke-Adb @('pull', $DevicePath, $LocalPath) | Out-Null
}

function Get-ErrorLines {
    $log = & $adb -s $Serial logcat -d -v brief 2>$null
    return $log | Where-Object {
        $_ -match 'FATAL EXCEPTION|FlutterError|RenderFlex|overflowed|E/flutter|E/MethodChannel|Unable to load widget|Dart Error|Exception caught'
    }
}

if ($FontTextOnly) {
    $OutputRoot = 'F:\xm\ying\outputs\widget-font-text-mixed-test'
}
if ($EveryElement) {
    $OutputRoot = 'F:\xm\ying\outputs\widget-every-element-mixed-test'
}

New-Item -ItemType Directory -Force -Path $OutputRoot | Out-Null
New-Item -ItemType Directory -Force -Path "$OutputRoot\prefs" | Out-Null
New-Item -ItemType Directory -Force -Path "$OutputRoot\settings" | Out-Null
New-Item -ItemType Directory -Force -Path "$OutputRoot\home" | Out-Null
New-Item -ItemType Directory -Force -Path "$OutputRoot\logs" | Out-Null

if (-not $SkipInstall -and (Test-Path $ApkPath)) {
    Invoke-Adb @('install', '-r', '-d', $ApkPath) | Out-Null
    Start-Sleep -Seconds 1
} elseif (-not $SkipInstall) {
    Write-Warning "APK not found: $ApkPath"
}

$eventsJson = Get-EventsJson
$scenarios = if ($EveryElement) {
    Get-EveryElementScenarios
} elseif ($FontTextOnly) {
    Get-FontTextScenarios
} else {
    Get-Scenarios
}

$summary = [System.Collections.Generic.List[object]]::new()
$scenarioIndex = 0
foreach ($scenario in $scenarios) {
    $scenarioIndex++
    if ($scenarioIndex -lt $StartIndex) {
        continue
    }
    if ($EndIndex -gt 0 -and $scenarioIndex -gt $EndIndex) {
        break
    }
    if ($MaxScenarios -gt 0 -and $scenarioIndex -ge ($StartIndex + $MaxScenarios)) {
        break
    }
    $name = $scenario.name
    $settings = $scenario.settings
    $xml = New-PrefsXml -Settings $settings -EventsJson $eventsJson
    $prefsLocal = "$OutputRoot\prefs\$name.xml"
    [System.IO.File]::WriteAllText(
        $prefsLocal,
        $xml,
        [System.Text.UTF8Encoding]::new($false)
    )

    Invoke-Adb @('push', $prefsLocal, '/data/local/tmp/flutter_prefs.xml') | Out-Null
    Invoke-Adb @('shell', 'run-as', 'com.jiuxina.ying', 'cp', '/data/local/tmp/flutter_prefs.xml', 'shared_prefs/FlutterSharedPreferences.xml')
    Invoke-Adb @('shell', 'run-as', 'com.jiuxina.ying', 'cp', '/data/local/tmp/flutter_prefs.xml', 'shared_prefs/FlutterSharedPreferences.xml.bak')

    Invoke-Adb @('logcat', '-c')
    Reset-App
    Open-WidgetSettings
    Scroll-To-Bottom

    $settingsPng = "$OutputRoot\settings\$name-settings.png"
    $settingsXml = "$OutputRoot\settings\$name-settings.xml"
    Save-Screen '/sdcard/mix_settings.png' $settingsPng
    Save-UiDump '/sdcard/mix_settings.xml' $settingsXml

    Invoke-Adb @('shell', 'input', 'keyevent', 'KEYCODE_HOME')
    Start-Sleep -Seconds 5
    $homePng = "$OutputRoot\home\$name-home.png"
    $homeXml = "$OutputRoot\home\$name-home.xml"
    Save-Screen '/sdcard/mix_home.png' $homePng
    Save-UiDump '/sdcard/mix_home.xml' $homeXml

    $errors = Get-ErrorLines
    $errorText = if ($errors.Count -eq 0) { '' } else { ($errors | Select-Object -First 20) -join "`n" }
    [System.IO.File]::WriteAllText(
        "$OutputRoot\logs\$name-errors.txt",
        $errorText,
        [System.Text.UTF8Encoding]::new($false)
    )

    Invoke-Adb @('shell', 'run-as', 'com.jiuxina.ying', 'cat', 'shared_prefs/HomeWidgetPreferences.xml') |
        Set-Content -Path "$OutputRoot\logs\$name-widget-prefs.xml" -Encoding UTF8

    $summary.Add([pscustomobject]@{
        Scenario = $name
        SettingsPng = $settingsPng
        HomePng = $homePng
        ErrorCount = $errors.Count
        Errors = $errorText
    })
    $summary | Export-Csv -Path "$OutputRoot\summary.csv" -NoTypeInformation -Encoding UTF8
    Write-Host "[$scenarioIndex/$($scenarios.Count)] $name errors=$($errors.Count)"
}

$summary | Export-Csv -Path "$OutputRoot\summary.csv" -NoTypeInformation -Encoding UTF8
Write-Host "Done. Summary: $OutputRoot\summary.csv"
