$jsonFile = "C:\Interesting\repos\rag\bible-agent\Bible Quotations.json"
$content = Get-Content $jsonFile -Raw -Encoding UTF8

# Fix 1: Update trigger to connect to both Bibles
$oldTrigger = @'
                        "When clicking 'Execute workflow'":  {
                                                                 "main":  [
                                                                              [
                                                                                  {
                                                                                      "node":  "HTTP Request",
                                                                                      "type":  "main",
                                                                                      "index":  0
                                                                                  }
                                                                              ]
                                                                          ]
                                                             },
'@

$newTrigger = @'
                        "When clicking 'Execute workflow'":  {
                                                                 "main":  [
                                                                              [
                                                                                  {
                                                                                      "node":  "HTTP Request - Download Bible PDF",
                                                                                      "type":  "main",
                                                                                      "index":  0
                                                                                  },
                                                                                  {
                                                                                      "node":  "🇷🇺 Download Russian Bible PDF",
                                                                                      "type":  "main",
                                                                                      "index":  0
                                                                                  }
                                                                              ]
                                                                          ]
                                                             },
'@

$content = $content -replace [regex]::Escape($oldTrigger), $newTrigger

[System.IO.File]::WriteAllText($jsonFile, $content, [System.Text.UTF8Encoding]::new($false))
Write-Host "Fixed trigger connection"
