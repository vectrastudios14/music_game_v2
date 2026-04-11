$arabicPath = "assets\songs_arabic.json"
$englishPath = "assets\songs.json"

$mapping = @{
    # ARABIC MALE
    "Talal Maddah"            = "male"
    "Abdel Hadi Bel Khayat"   = "male"
    "Abdul Karim Abdul Qader" = "male"
    "Rashed Al Majid"         = "male"
    "Mohammed Abdu"           = "male"
    "Majid Al Mohandis"       = "male"
    "Amr Diab"                = "male"
    "Kadim Al Sahir"          = "male"
    "Nabeel Shuail"           = "male"
    "Abdallah Al Rowaished"   = "male"
    "Rabeh Saqer"             = "male"
    "Hussein Al Jassmi"       = "male"
    "Tamer Hosny"             = "male"
    "Mohamed Hamaki"          = "male"
    "Fadel Chaker"            = "male"
    "Wael Kfoury"             = "male"
    "Ramy Ayach"              = "male"
    "Assi El Helani"          = "male"
    "George Wassouf"          = "male"
    "Saber Rebai"             = "male"

    # ARABIC FEMALE
    "Fairuz"                  = "female"
    "Umm Kulthum"             = "female"
    "Ahlam"                   = "female"
    "Nawal El Kuwaitia"       = "female"
    "Assala"                  = "female"
    "Sherine"                 = "female"
    "Nancy Ajram"             = "female"
    "Elissa"                  = "female"
    "Najwa Karam"             = "female"
    "Myriam Fares"            = "female"
    "Angham"                  = "female"
    "Latifa"                  = "female"
    "Haifa Wehbe"             = "female"
    "Carole Samaha"           = "female"
    "Yara"                    = "female"
    "Asma Lmnawar"            = "female"
    "Balqees"                 = "female"

    # ENGLISH MALE
    "Michael Jackson"         = "male"
    "Elvis Presley"           = "male"
    "Prince"                  = "male"
    "George Michael"          = "male"
    "Elton John"              = "male"
    "David Bowie"             = "male"
    "Freddie Mercury"         = "male"
    "Justin Bieber"           = "male"
    "Ed Sheeran"              = "male"
    "Sam Smith"               = "male"
    "The Weeknd"              = "male"
    "Drake"                   = "male"
    "Bruno Mars"              = "male"
    "Harry Styles"            = "male"
    "Lewis Capaldi"           = "male"
    "Shawn Mendes"            = "male"
    "John Legend"             = "male"
    "Usher"                   = "male"
    "Pharrell Williams"       = "male"
    "Billy Joel"              = "male"
    "Bruce Springsteen"       = "male"
    "Phil Collins"            = "male"
    "Rod Stewart"             = "male"
    "Bryan Adams"             = "male"
    "Bob Dylan"               = "male"
    "Stevie Wonder"           = "male"
    "Marvin Gaye"             = "male"
    "Otis Redding"            = "male"
    "Ray Charles"             = "male"
    "James Brown"             = "male"
    "Frank Sinatra"           = "male"
    "Dean Martin"             = "male"
    "Nat King Cole"           = "male"
    "Rick Astley"             = "male"

    # ENGLISH FEMALE
    "Whitney Houston"         = "female"
    "Madonna"                 = "female"
    "Celine Dion"             = "female"
    "Mariah Carey"            = "female"
    "Adele"                   = "female"
    "Beyoncé"                 = "female"
    "Taylor Swift"            = "female"
    "Lady Gaga"               = "female"
    "Rihanna"                 = "female"
    "Katy Perry"              = "female"
    "Ariana Grande"           = "female"
    "Billie Eilish"           = "female"
    "Dua Lipa"                = "female"
    "Olivia Rodrigo"          = "female"
    "Miley Cyrus"             = "female"
    "Amy Winehouse"           = "female"
    "Tina Turner"             = "female"
    "Cher"                    = "female"
    "Aretha Franklin"         = "female"
    "Dolly Parton"            = "female"
    "Cyndi Lauper"            = "female"
    "Janet Jackson"           = "female"
    "Alicia Keys"             = "female"
    "Kelly Clarkson"          = "female"
    "Pink"                    = "female"
    "Shakira"                 = "female"
    "Britney Spears"          = "female"
    "Christina Aguilera"      = "female"
    "Norah Jones"             = "female"
    "Joni Mitchell"           = "female"
    "Carole King"             = "female"
    "Janis Joplin"            = "female"
    "Diana Ross"              = "female"
    "Donna Summer"            = "female"

    # GROUPS
    "Queen"                   = "group"
    "ABBA"                    = "group"
    "The Beatles"             = "group"
    "The Rolling Stones"      = "group"
    "Bee Gees"                = "group"
    "Fleetwood Mac"           = "group"
    "Pink Floyd"              = "group"
    "Led Zeppelin"            = "group"
    "AC/DC"                   = "group"
    "Bon Jovi"                = "group"
    "Aerosmith"               = "group"
    "Guns N' Roses"           = "group"
    "The Police"              = "group"
    "U2"                      = "group"
    "Coldplay"                = "group"
    "Maroon 5"                = "group"
    "One Direction"           = "group"
    "Destiny's Child"         = "group"
    "Spice Girls"             = "group"
    "Little Mix"              = "group"
    "Blackpink"               = "group"
    "BTS"                     = "group"
}

function Update-Gender($path) {
    if (Test-Path $path) {
        $fullPath = (Get-Item $path).FullName
        Write-Host "Updating $fullPath"
        
        # Use System.IO.File for absolute control over encoding (UTF8 no BOM)
        $utf8 = New-Object System.Text.UTF8Encoding($false)
        $json = [System.IO.File]::ReadAllText($fullPath, $utf8)
        
        $data = $json | ConvertFrom-Json
        foreach ($song in $data) {
            if ($mapping.ContainsKey($song.artist)) {
                $song | Add-Member -MemberType NoteProperty -Name "gender" -Value $mapping[$song.artist] -Force
            }
            else {
                # Keep existing if any, or null
                if (-not (Get-Member -InputObject $song -Name "gender")) {
                    $song | Add-Member -MemberType NoteProperty -Name "gender" -Value $null -Force
                }
            }
        }
        
        $newJson = $data | ConvertTo-Json -Depth 10
        [System.IO.File]::WriteAllText($fullPath, $newJson, $utf8)
        Write-Host "Successfully updated $path"
    }
    else {
        Write-Host "Path not found: $path"
    }
}

Update-Gender $arabicPath
Update-Gender $englishPath
